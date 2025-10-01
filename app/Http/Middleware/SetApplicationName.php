<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use App\Models\Setting;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Log;

class SetApplicationName
{
    public function handle(Request $request, Closure $next)
    {
        try {
            // Only attempt to load from DB if the settings table exists
            if (Schema::hasTable('settings')) {
                try {
                    $appNameSetting = Setting::where('key', 'app_name')->first();

                    if ($appNameSetting) {
                        Config::set('app.name', $appNameSetting->value);
                    } else {
                        Config::set('app.name', env('APP_NAME', 'Laravel'));
                    }
                } catch (\Exception $e) {
                    // Catch any database connection or query errors
                    Config::set('app.name', env('APP_NAME', 'Laravel'));
                }
            } else {
                Config::set('app.name', env('APP_NAME', 'Laravel'));
            }
        } catch (\Exception $e) {
            // If anything fails (including Schema check), just use env
            Config::set('app.name', env('APP_NAME', 'Laravel'));
        }

        return $next($request);
    }
}
