<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Helpers\NetworkHelper;

class UpdateNetworkConfig extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'network:update';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Update network configuration with current IP address';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $this->info('Updating network configuration...');

        $currentIp = NetworkHelper::getServerIp();
        $this->info("Current server IP: {$currentIp}");

        if (NetworkHelper::updateEnvWithCurrentIp()) {
            $this->info('✅ Network configuration updated successfully!');
            $this->info('APP_URL and VITE_API_BASE_URL have been updated with current IP.');

            return Command::SUCCESS;
        } else {
            $this->error('❌ Failed to update network configuration.');
            return Command::FAILURE;
        }
    }
}
