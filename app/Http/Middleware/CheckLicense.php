<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\Setting; // Import the Setting model
use Carbon\Carbon; // Import Carbon for date handling
use App\Models\User; // Import User model
use Illuminate\Support\Facades\Log; // Import Log facade

class CheckLicense
{
    /**
     * Handle an incoming request.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     * @return \Symfony\Component\HttpFoundation\Response
     */
    public function handle(Request $request, Closure $next)
    {
        // Only apply this check to authenticated users trying to access admin routes
        // and not when they are already on the license expired page.
        if (Auth::check() && $request->routeIs('admin.*') && !$request->routeIs('license.expired')) {
            $user = Auth::user();
            Log::info('CheckLicense middleware triggered', ['user_id' => $user->id, 'route' => $request->route()->getName()]);

            // If the user is a superadmin, bypass all license checks and proceed.
            if ($user && $user->isSuperAdmin()) {
                Log::info('Superadmin bypassing license check', ['user_id' => $user->id]);
                return $next($request);
            }

            // For all other authenticated users (non-superadmins) accessing admin routes,
            // perform the global application license check first.
            $licenseKeySetting = Setting::where('key', 'license_key')->first();
            $expirationDateSetting = Setting::where('key', 'license_expiration_date')->first();

            $licenseKey = $licenseKeySetting ? $licenseKeySetting->value : null;
            $expirationDate = $expirationDateSetting ? ($expirationDateSetting->value ? Carbon::parse($expirationDateSetting->value) : null) : null;

            $isLicensed = !empty($licenseKey);
            $isExpired = $expirationDate && $expirationDate->isPast();

            Log::info('Global license check', [
                'has_key' => $isLicensed,
                'expiration' => $expirationDate ? $expirationDate->toDateTimeString() : 'N/A',
                'is_expired' => $isExpired
            ]);

            // If no global license key is set OR global license is expired
            if (!$isLicensed || $isExpired) {
                Log::warning('Global license check failed - logging out user', ['user_id' => $user->id]);
                Auth::logout(); // Log out the user
                $request->session()->invalidate(); // Invalidate the session
                $request->session()->regenerateToken(); // Regenerate CSRF token
                session()->flash('error', __('Your application license is invalid or has expired. Please contact your administrator.'));
                return redirect()->route('login');
            }

            // After the global license check, check the individual user's license status.
            // This block will only be reached by non-superadmins if the global license is valid.
            $user->load('license');
            Log::info('Individual license check', [
                'user_id' => $user->id,
                'has_license' => $user->license ? 'yes' : 'no',
                'is_used' => $user->license ? $user->license->is_used : 'N/A',
                'expires_at' => $user->license && $user->license->expires_at ? $user->license->expires_at->toDateTimeString() : 'N/A',
            ]);

            if (!$user->hasActiveLicense()) {
                Log::warning('Individual license check failed - logging out user', ['user_id' => $user->id]);
                Auth::logout(); // Log out the user
                $request->session()->invalidate(); // Invalidate the session
                $request->session()->regenerateToken(); // Regenerate CSRF token
                session()->flash('error', __('Your license is invalid or has expired. Please contact your administrator to activate a license.'));
                return redirect()->route('login');
            }

            Log::info('License checks passed', ['user_id' => $user->id]);
        }

        return $next($request);
    }
}

