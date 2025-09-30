<?php

namespace App\Helpers;

class NetworkHelper
{
    /**
     * Get the current server IP address (dynamic detection)
     *
     * @return string
     */
    public static function getServerIp(): string
    {
        // Try to get from server variables first
        $ip = $_SERVER['SERVER_ADDR'] ?? null;

        if (!$ip || $ip === '127.0.0.1' || $ip === '::1') {
            // Fallback: Use shell command to get actual network IP
            $ip = self::getNetworkIpFromShell();
        }

        return $ip ?: 'localhost';
    }

    /**
     * Get network IP from shell command (works on Linux/NanoPi)
     *
     * @return string|null
     */
    private static function getNetworkIpFromShell(): ?string
    {
        try {
            // Get primary network interface IP (excluding loopback)
            $command = "ip addr show | grep 'inet ' | grep -v '127.0.0.1' | head -1 | awk '{print $2}' | cut -d'/' -f1";
            $ip = trim(shell_exec($command));

            if ($ip && filter_var($ip, FILTER_VALIDATE_IP)) {
                return $ip;
            }
        } catch (\Exception $e) {
            // Silent fail
        }

        return null;
    }

    /**
     * Get the base URL for the application
     *
     * @return string
     */
    public static function getBaseUrl(): string
    {
        $ip = self::getServerIp();
        $port = $_SERVER['SERVER_PORT'] ?? '8000';

        return "http://{$ip}:{$port}";
    }

    /**
     * Update .env file with current IP address
     *
     * @return bool
     */
    public static function updateEnvWithCurrentIp(): bool
    {
        try {
            $envPath = base_path('.env');

            if (!file_exists($envPath)) {
                return false;
            }

            $baseUrl = self::getBaseUrl();
            $envContent = file_get_contents($envPath);

            // Update APP_URL
            $envContent = preg_replace(
                '/^APP_URL=.*/m',
                "APP_URL={$baseUrl}",
                $envContent
            );

            // Update VITE_API_BASE_URL
            if (preg_match('/^VITE_API_BASE_URL=.*/m', $envContent)) {
                $envContent = preg_replace(
                    '/^VITE_API_BASE_URL=.*/m',
                    "VITE_API_BASE_URL={$baseUrl}",
                    $envContent
                );
            } else {
                $envContent .= "\nVITE_API_BASE_URL={$baseUrl}\n";
            }

            file_put_contents($envPath, $envContent);

            return true;
        } catch (\Exception $e) {
            return false;
        }
    }
}
