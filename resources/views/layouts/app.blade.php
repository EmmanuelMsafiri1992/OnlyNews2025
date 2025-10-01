<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}" dir="{{ (app()->getLocale() === 'he' || app()->getLocale() === 'ar') ? 'rtl' : 'ltr' }}">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="viewport-fit=cover, width=device-width, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>{{ config('app.name', 'School News') }}</title>

    <meta name="csrf-token" content="{{ csrf_token() }}">

    {{-- Preconnect to Google Fonts for faster loading --}}
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    {{-- Using Inter font for better readability across devices, with fallbacks --}}
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">

    {{-- Removed old Nunito font link to use Inter, or you can keep both if needed --}}
    {{-- <link href="https://fonts.googleapis.com/css?family=Nunito" rel="stylesheet"> --}}
</head>

{{-- Ensure body takes full height and uses Inter font --}}
<body class="bg-white font-inter antialiased min-h-screen flex flex-col">

    {{-- Blade conditional logic to decide if Vue app should load --}}
    @php
        // Define URL paths where the Vue app should NOT be mounted.
        // These are typically Blade-only pages (authentication, admin panels).
        $noVuePaths = [
            'login',
            'register',
            'password/*', // Covers all password reset routes
            'admin*', // Covers all routes under the '/admin' prefix
        ];

        $loadVueApp = true; // Assume Vue app should load by default

        foreach ($noVuePaths as $path) {
            if (request()->is($path)) {
                $loadVueApp = false;
                break;
            }
        }
    @endphp

    @if ($loadVueApp)
        {{-- This is the mount point for your Vue.js application.
             Your resources/js/app.js will mount App.vue here. --}}
        <div id="app" class="flex-1">
            {{-- Fallback content for browsers that don't support modern JavaScript --}}
            <noscript>
                <div style="min-height: 100vh; display: flex; align-items: center; justify-center; flex-direction: column; padding: 2rem; text-align: center; font-family: Inter, sans-serif;">
                    <h1 style="font-size: 2rem; margin-bottom: 1rem;">JavaScript Required</h1>
                    <p style="font-size: 1.25rem; color: #666;">This application requires JavaScript to be enabled.</p>
                </div>
            </noscript>
            {{-- Loading fallback for older browsers --}}
            <div id="browser-check" style="display: none;">
                <div style="min-height: 100vh; display: flex; align-items: center; justify-center; flex-direction: column; padding: 2rem; text-align: center; font-family: Inter, sans-serif;">
                    <h1 style="font-size: 2rem; margin-bottom: 1rem;">Browser Not Supported</h1>
                    <p style="font-size: 1.25rem; color: #666; margin-bottom: 2rem;">Your browser does not support modern features required by this application.</p>
                    <p style="font-size: 1rem; color: #999;">Please use a modern browser or update your current browser.</p>
                </div>
            </div>
        </div>

        {{-- Browser compatibility check script (runs before Vue) --}}
        <script>
            (function() {
                // Check for essential modern browser features
                var isModernBrowser = (
                    'Promise' in window &&
                    'fetch' in window &&
                    'Map' in window &&
                    'Set' in window
                );

                if (!isModernBrowser) {
                    document.getElementById('browser-check').style.display = 'flex';
                    document.getElementById('app').style.display = 'none';
                    return;
                }

                // Add a timeout to detect if Vue app fails to load
                var appMountTimeout = setTimeout(function() {
                    var appElement = document.getElementById('app');
                    if (appElement && appElement.children.length === 2) { // Only noscript and browser-check divs
                        document.getElementById('browser-check').style.display = 'flex';
                    }
                }, 10000); // 10 second timeout

                // Clear timeout if app loads successfully
                window.addEventListener('load', function() {
                    setTimeout(function() {
                        var appElement = document.getElementById('app');
                        if (appElement && appElement.children.length > 2) {
                            clearTimeout(appMountTimeout);
                        }
                    }, 1000);
                });
            })();
        </script>

        {{-- Load Vite assets manually for Laravel 8 compatibility --}}
        @if (file_exists(public_path('build/manifest.json')))
            @php
                $manifest = json_decode(file_get_contents(public_path('build/manifest.json')), true);
            @endphp
            @if (isset($manifest['resources/css/app.css']))
                <link rel="stylesheet" href="{{ asset('build/' . $manifest['resources/css/app.css']['file']) }}">
            @endif
            @if (isset($manifest['resources/js/app.js']))
                @if (isset($manifest['resources/js/app.js']['css']))
                    @foreach ($manifest['resources/js/app.js']['css'] as $css)
                        <link rel="stylesheet" href="{{ asset('build/' . $css) }}">
                    @endforeach
                @endif
                <script type="module" src="{{ asset('build/' . $manifest['resources/js/app.js']['file']) }}"></script>
            @endif
        @endif
    @else
        {{-- For authentication pages, and other dedicated Blade-only pages (like admin panel list/forms),
             only render the content specified in their respective Blade files.
             The <div id="app-blade-content"> is optional, but helps differentiate. --}}
        <div id="app-blade-content" class="min-h-screen flex-1">
            @yield('content')
        </div>

        {{-- Load only CSS for Blade-only pages --}}
        @if (file_exists(public_path('build/manifest.json')))
            @php
                $manifest = json_decode(file_get_contents(public_path('build/manifest.json')), true);
            @endphp
            @if (isset($manifest['resources/css/app.css']))
                <link rel="stylesheet" href="{{ asset('build/' . $manifest['resources/css/app.css']['file']) }}">
            @endif
        @endif
    @endif

</body>

</html>
