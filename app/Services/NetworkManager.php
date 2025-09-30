<?php

namespace App\Services;

use Illuminate\Support\Facades\Log;
use Exception;

class NetworkManager
{
    /**
     * Get current network configuration
     */
    public function getCurrentNetworkConfig()
    {
        try {
            // Get current IP configuration
            $currentIp = $this->getCurrentIpAddress();
            $networkMode = $this->detectNetworkMode();

            return [
                'current_ip' => $currentIp,
                'mode' => $networkMode,
                'interface' => $this->getPrimaryInterface(),
                'gateway' => $this->getGateway(),
                'dns_servers' => $this->getDnsServers()
            ];
        } catch (Exception $e) {
            Log::error('Failed to get network config: ' . $e->getMessage());
            return [
                'current_ip' => 'Unknown',
                'mode' => 'unknown',
                'interface' => 'eth0',
                'gateway' => '',
                'dns_servers' => []
            ];
        }
    }

    /**
     * Apply network settings (DHCP or Static)
     */
    public function applyNetworkSettings($settings)
    {
        try {
            $interface = $settings['interface'] ?? 'eth0';
            $mode = $settings['mode'] ?? 'dhcp';

            if ($mode === 'static') {
                return $this->configureStaticIp($settings);
            } else {
                return $this->configureDhcp($interface);
            }
        } catch (Exception $e) {
            Log::error('Failed to apply network settings: ' . $e->getMessage());
            return [
                'success' => false,
                'message' => 'Failed to apply network settings: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Configure static IP
     */
    private function configureStaticIp($settings)
    {
        $interface = $settings['interface'] ?? 'eth0';
        $ipAddress = $settings['ip_address'];
        $subnet = $settings['subnet_mask'] ?? '255.255.255.0';
        $gateway = $settings['gateway'];
        $dns = $settings['dns_server'] ?? '8.8.8.8';

        // Validate IP address format
        if (!filter_var($ipAddress, FILTER_VALIDATE_IP)) {
            return ['success' => false, 'message' => 'Invalid IP address format'];
        }

        if (!filter_var($gateway, FILTER_VALIDATE_IP)) {
            return ['success' => false, 'message' => 'Invalid gateway address format'];
        }

        // For Ubuntu/Debian systems - configure netplan
        $netplanConfig = $this->generateNetplanConfig($interface, $ipAddress, $subnet, $gateway, $dns);

        try {
            // Write netplan configuration
            $netplanFile = '/etc/netplan/50-bellnews-static.yaml';
            file_put_contents($netplanFile, $netplanConfig);

            // Apply netplan configuration
            $output = shell_exec('sudo netplan apply 2>&1');

            Log::info('Static IP configured', [
                'interface' => $interface,
                'ip' => $ipAddress,
                'gateway' => $gateway,
                'output' => $output
            ]);

            return [
                'success' => true,
                'message' => 'Static IP configuration applied successfully',
                'new_ip' => $ipAddress
            ];
        } catch (Exception $e) {
            Log::error('Failed to write netplan config: ' . $e->getMessage());
            return [
                'success' => false,
                'message' => 'Failed to apply static IP configuration'
            ];
        }
    }

    /**
     * Configure DHCP
     */
    private function configureDhcp($interface)
    {
        try {
            // Remove static configuration and enable DHCP
            $netplanConfig = $this->generateDhcpConfig($interface);
            $netplanFile = '/etc/netplan/50-bellnews-static.yaml';

            file_put_contents($netplanFile, $netplanConfig);

            // Apply netplan configuration
            $output = shell_exec('sudo netplan apply 2>&1');

            // Wait a moment and get new IP
            sleep(3);
            $newIp = $this->getCurrentIpAddress();

            Log::info('DHCP configured', [
                'interface' => $interface,
                'new_ip' => $newIp,
                'output' => $output
            ]);

            return [
                'success' => true,
                'message' => 'DHCP configuration applied successfully',
                'new_ip' => $newIp
            ];
        } catch (Exception $e) {
            Log::error('Failed to configure DHCP: ' . $e->getMessage());
            return [
                'success' => false,
                'message' => 'Failed to apply DHCP configuration'
            ];
        }
    }

    /**
     * Generate netplan configuration for static IP
     */
    private function generateNetplanConfig($interface, $ipAddress, $subnet, $gateway, $dns)
    {
        // Convert subnet mask to CIDR notation
        $cidr = $this->subnetMaskToCidr($subnet);

        return "network:\n" .
               "  version: 2\n" .
               "  ethernets:\n" .
               "    $interface:\n" .
               "      addresses:\n" .
               "        - $ipAddress/$cidr\n" .
               "      gateway4: $gateway\n" .
               "      nameservers:\n" .
               "        addresses:\n" .
               "          - $dns\n" .
               "          - 8.8.4.4\n";
    }

    /**
     * Generate netplan configuration for DHCP
     */
    private function generateDhcpConfig($interface)
    {
        return "network:\n" .
               "  version: 2\n" .
               "  ethernets:\n" .
               "    $interface:\n" .
               "      dhcp4: true\n" .
               "      dhcp6: false\n";
    }

    /**
     * Get current IP address
     */
    private function getCurrentIpAddress()
    {
        $command = "ip route get 1.1.1.1 | awk '{print $7}' | head -1";
        $ip = trim(shell_exec($command));
        return $ip ?: 'Unknown';
    }

    /**
     * Detect current network mode (DHCP or Static)
     */
    private function detectNetworkMode()
    {
        // Check if there are any netplan static configurations
        $netplanFiles = glob('/etc/netplan/*.yaml');
        foreach ($netplanFiles as $file) {
            $content = file_get_contents($file);
            if (strpos($content, 'addresses:') !== false && strpos($content, 'dhcp4: true') === false) {
                return 'static';
            }
        }
        return 'dhcp';
    }

    /**
     * Get primary network interface
     */
    private function getPrimaryInterface()
    {
        $command = "ip route | grep default | awk '{print $5}' | head -1";
        $interface = trim(shell_exec($command));
        return $interface ?: 'eth0';
    }

    /**
     * Get current gateway
     */
    private function getGateway()
    {
        $command = "ip route | grep default | awk '{print $3}' | head -1";
        $gateway = trim(shell_exec($command));
        return $gateway ?: '';
    }

    /**
     * Get DNS servers
     */
    private function getDnsServers()
    {
        $command = "grep nameserver /etc/resolv.conf | awk '{print $2}'";
        $output = shell_exec($command);
        return $output ? explode("\n", trim($output)) : [];
    }

    /**
     * Convert subnet mask to CIDR notation
     */
    private function subnetMaskToCidr($subnetMask)
    {
        $cidrMap = [
            '255.255.255.0' => 24,
            '255.255.0.0' => 16,
            '255.0.0.0' => 8,
            '255.255.255.128' => 25,
            '255.255.255.192' => 26,
            '255.255.255.224' => 27,
            '255.255.255.240' => 28,
            '255.255.255.248' => 29,
            '255.255.255.252' => 30
        ];

        return $cidrMap[$subnetMask] ?? 24; // Default to /24
    }
}