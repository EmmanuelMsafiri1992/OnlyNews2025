<?php

namespace App\Services;

use Illuminate\Support\Facades\Log;
use Exception;

class NetworkManager
{
    private $interfacesFile = "/etc/network/interfaces";
    private $dhcpcdFile = "/etc/dhcpcd.conf";
    private $netplanDir = "/etc/netplan";
    private $backupDir;
    private $networkSystem;

    public function __construct()
    {
        $this->backupDir = storage_path('network_backups');

        if (!file_exists($this->backupDir)) {
            @mkdir($this->backupDir, 0755, true);
        }

        $this->networkSystem = $this->detectNetworkSystem();
    }

    /**
     * Detect which network management system is in use
     */
    private function detectNetworkSystem()
    {
        if (is_dir($this->netplanDir) && count(glob($this->netplanDir . '/*.yaml')) > 0) {
            return 'netplan';
        }

        if (file_exists($this->dhcpcdFile)) {
            return 'dhcpcd';
        }

        if (file_exists($this->interfacesFile)) {
            return 'interfaces';
        }

        return 'unknown';
    }

    /**
     * Get the primary network interface
     */
    private function getPrimaryInterface()
    {
        try {
            $result = shell_exec('ip route show default 2>/dev/null');

            if ($result && preg_match('/default.*dev\s+(\S+)/', $result, $matches)) {
                return $matches[1];
            }
        } catch (Exception $e) {
            Log::error('Failed to detect primary interface: ' . $e->getMessage());
        }

        return 'eth0'; // Default fallback
    }

    /**
     * Backup current network configuration
     */
    private function backupConfig()
    {
        try {
            $timestamp = time();

            if ($this->networkSystem === 'netplan') {
                $files = glob($this->netplanDir . '/*.yaml');
                foreach ($files as $file) {
                    $basename = basename($file);
                    $backupPath = $this->backupDir . '/' . $basename . '.' . $timestamp;
                    copy($file, $backupPath);
                }
            } elseif ($this->networkSystem === 'dhcpcd') {
                copy($this->dhcpcdFile, $this->backupDir . '/dhcpcd.conf.' . $timestamp);
            } elseif ($this->networkSystem === 'interfaces') {
                copy($this->interfacesFile, $this->backupDir . '/interfaces.' . $timestamp);
            }

            return true;
        } catch (Exception $e) {
            Log::error('Backup failed: ' . $e->getMessage());
            return false;
        }
    }

    /**
     * Convert subnet mask to CIDR notation
     */
    private function subnetMaskToCidr($subnetMask)
    {
        try {
            $parts = explode('.', $subnetMask);
            $binary = '';

            foreach ($parts as $part) {
                $binary .= str_pad(decbin((int)$part), 8, '0', STR_PAD_LEFT);
            }

            return (string)substr_count($binary, '1');
        } catch (Exception $e) {
            return '24'; // Default /24
        }
    }

    /**
     * Apply network configuration
     */
    public function applyNetworkConfig(array $config)
    {
        // Validate input
        if (!isset($config['ipType'])) {
            return ['status' => 'error', 'message' => 'IP type is required'];
        }

        // Backup current config
        if (!$this->backupConfig()) {
            return ['status' => 'error', 'message' => 'Failed to backup current configuration'];
        }

        $interface = $this->getPrimaryInterface();

        try {
            if ($this->networkSystem === 'netplan') {
                $result = $this->applyNetplanConfig($interface, $config);
            } elseif ($this->networkSystem === 'dhcpcd') {
                $result = $this->applyDhcpcdConfig($interface, $config);
            } elseif ($this->networkSystem === 'interfaces') {
                $result = $this->applyInterfacesConfig($interface, $config);
            } else {
                return ['status' => 'error', 'message' => 'Unknown network management system'];
            }

            if ($result['status'] === 'success') {
                $this->restartNetworking();
            }

            return $result;
        } catch (Exception $e) {
            Log::error('Failed to apply network config: ' . $e->getMessage());
            return ['status' => 'error', 'message' => $e->getMessage()];
        }
    }

    /**
     * Apply netplan configuration
     */
    private function applyNetplanConfig($interface, $config)
    {
        $netplanFile = $this->netplanDir . '/01-netcfg.yaml';

        if ($config['ipType'] === 'static') {
            $cidr = $this->subnetMaskToCidr($config['subnetMask'] ?? '255.255.255.0');

            $netplanConfig = [
                'network' => [
                    'version' => 2,
                    'renderer' => 'networkd',
                    'ethernets' => [
                        $interface => [
                            'addresses' => [$config['ipAddress'] . '/' . $cidr],
                            'gateway4' => $config['gateway'] ?? '',
                            'nameservers' => [
                                'addresses' => [$config['dnsServer'] ?? '8.8.8.8']
                            ]
                        ]
                    ]
                ]
            ];
        } else {
            $netplanConfig = [
                'network' => [
                    'version' => 2,
                    'renderer' => 'networkd',
                    'ethernets' => [
                        $interface => [
                            'dhcp4' => true
                        ]
                    ]
                ]
            ];
        }

        $yaml = $this->arrayToYaml($netplanConfig);
        file_put_contents($netplanFile, $yaml);
        chmod($netplanFile, 0600);

        return ['status' => 'success', 'message' => 'Network configuration updated'];
    }

    /**
     * Apply dhcpcd configuration
     */
    private function applyDhcpcdConfig($interface, $config)
    {
        $content = file_get_contents($this->dhcpcdFile);

        // Remove existing static config for this interface
        $content = preg_replace("/interface $interface.*?(?=\n\n|\ninterface|\z)/s", '', $content);

        if ($config['ipType'] === 'static') {
            $staticConfig = "\n\ninterface $interface\n";
            $staticConfig .= "static ip_address=" . $config['ipAddress'] . "/" . $this->subnetMaskToCidr($config['subnetMask'] ?? '255.255.255.0') . "\n";
            $staticConfig .= "static routers=" . ($config['gateway'] ?? '') . "\n";
            $staticConfig .= "static domain_name_servers=" . ($config['dnsServer'] ?? '8.8.8.8') . "\n";

            $content .= $staticConfig;
        }

        file_put_contents($this->dhcpcdFile, $content);

        return ['status' => 'success', 'message' => 'Network configuration updated'];
    }

    /**
     * Apply interfaces configuration
     */
    private function applyInterfacesConfig($interface, $config)
    {
        $content = "# This file describes the network interfaces available on your system\n";
        $content .= "# and how to activate them. For more information, see interfaces(5).\n\n";
        $content .= "source /etc/network/interfaces.d/*\n\n";
        $content .= "# The loopback network interface\n";
        $content .= "auto lo\n";
        $content .= "iface lo inet loopback\n\n";
        $content .= "# The primary network interface\n";
        $content .= "auto $interface\n";

        if ($config['ipType'] === 'static') {
            $content .= "iface $interface inet static\n";
            $content .= "    address " . $config['ipAddress'] . "\n";
            $content .= "    netmask " . ($config['subnetMask'] ?? '255.255.255.0') . "\n";
            $content .= "    gateway " . ($config['gateway'] ?? '') . "\n";
            $content .= "    dns-nameservers " . ($config['dnsServer'] ?? '8.8.8.8') . "\n";
        } else {
            $content .= "iface $interface inet dhcp\n";
        }

        file_put_contents($this->interfacesFile, $content);

        return ['status' => 'success', 'message' => 'Network configuration updated'];
    }

    /**
     * Restart networking
     */
    private function restartNetworking()
    {
        try {
            if ($this->networkSystem === 'netplan') {
                shell_exec('netplan apply 2>&1');
            } elseif ($this->networkSystem === 'dhcpcd') {
                shell_exec('systemctl restart dhcpcd 2>&1');
            } else {
                shell_exec('systemctl restart networking 2>&1');
            }

            sleep(5); // Wait for network to stabilize
        } catch (Exception $e) {
            Log::error('Failed to restart networking: ' . $e->getMessage());
        }
    }

    /**
     * Convert array to YAML format
     */
    private function arrayToYaml($array, $indent = 0)
    {
        $yaml = '';
        $spaces = str_repeat('  ', $indent);

        foreach ($array as $key => $value) {
            if (is_array($value)) {
                $yaml .= $spaces . $key . ":\n";
                $yaml .= $this->arrayToYaml($value, $indent + 1);
            } else {
                if (is_bool($value)) {
                    $value = $value ? 'true' : 'false';
                } elseif (is_string($value) && !is_numeric($value)) {
                    $value = '"' . $value . '"';
                }
                $yaml .= $spaces . $key . ": " . $value . "\n";
            }
        }

        return $yaml;
    }

    /**
     * Get current network configuration
     */
    public function getCurrentConfig()
    {
        $interface = $this->getPrimaryInterface();
        $config = [];

        try {
            // Get IP address
            $result = shell_exec("ip addr show $interface 2>/dev/null");
            if (preg_match('/inet\s+(\d+\.\d+\.\d+\.\d+)\/(\d+)/', $result, $matches)) {
                $config['ipAddress'] = $matches[1];
                $config['cidr'] = $matches[2];
            }

            // Get gateway
            $result = shell_exec('ip route show default 2>/dev/null');
            if (preg_match('/default\s+via\s+(\d+\.\d+\.\d+\.\d+)/', $result, $matches)) {
                $config['gateway'] = $matches[1];
            }

            // Get DNS
            if (file_exists('/etc/resolv.conf')) {
                $resolv = file_get_contents('/etc/resolv.conf');
                if (preg_match('/nameserver\s+(\d+\.\d+\.\d+\.\d+)/', $resolv, $matches)) {
                    $config['dnsServer'] = $matches[1];
                }
            }

            // Determine if static or dynamic
            $config['ipType'] = $this->detectIpType($interface);

        } catch (Exception $e) {
            Log::error('Failed to get current network config: ' . $e->getMessage());
        }

        return $config;
    }

    /**
     * Detect if IP is static or dynamic
     */
    private function detectIpType($interface)
    {
        try {
            if ($this->networkSystem === 'netplan') {
                $files = glob($this->netplanDir . '/*.yaml');
                foreach ($files as $file) {
                    $content = file_get_contents($file);
                    if (strpos($content, $interface) !== false) {
                        if (strpos($content, 'dhcp4: true') !== false) {
                            return 'dynamic';
                        }
                        if (preg_match('/addresses:\s*\[/', $content) || preg_match('/addresses:\s*\n\s*-/', $content)) {
                            return 'static';
                        }
                    }
                }
            }
        } catch (Exception $e) {
            Log::error('Failed to detect IP type: ' . $e->getMessage());
        }

        return 'dynamic'; // Default
    }

    /**
     * Get network system type
     */
    public function getNetworkSystem()
    {
        return $this->networkSystem;
    }
}
