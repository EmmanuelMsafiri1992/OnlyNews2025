<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('settings', function (Blueprint $table) {
            $table->string('network_ip_type')->default('dynamic')->after('footer_copyright_text'); // 'dynamic' or 'static'
            $table->string('network_ip_address')->nullable()->after('network_ip_type');
            $table->string('network_subnet_mask')->nullable()->after('network_ip_address');
            $table->string('network_gateway')->nullable()->after('network_subnet_mask');
            $table->string('network_dns_server')->nullable()->after('network_gateway');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('settings', function (Blueprint $table) {
            $table->dropColumn(['network_ip_type', 'network_ip_address', 'network_subnet_mask', 'network_gateway', 'network_dns_server']);
        });
    }
};
