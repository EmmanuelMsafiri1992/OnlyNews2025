<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use Illuminate\Foundation\Auth\AuthenticatesUsers;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth; // Import Auth facade
use App\Models\User; // Import User model
use Illuminate\Support\Facades\Log; // Import Log facade

class LoginController extends Controller
{
    use AuthenticatesUsers;

    /**
     * Where to redirect users after login.
     *
     * @var string
     */
    protected $redirectTo = '/admin/dashboard'; // Default redirect for all authenticated users

    /**
     * Create a new controller instance.
     *
     * @return void
     */
    public function __construct()
    {
        $this->middleware('guest')->except('logout');
        $this->middleware('auth')->only('logout');
    }

    /**
     * Show the application's login form.
     *
     * @return \Illuminate\View\View
     */
    public function showLoginForm()
    {
        return view('auth.login');
    }

    /**
     * The user has been authenticated.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  mixed  $user
     * @return \Illuminate\Http\Response
     */
    protected function authenticated(Request $request, $user)
    {
        Log::info('User attempting login', ['user_id' => $user->id, 'email' => $user->email, 'role' => $user->role]);

        // If the authenticated user is a superadmin, they bypass all license checks.
        if ($user->isSuperAdmin()) {
            Log::info('Superadmin login successful', ['user_id' => $user->id]);
            return redirect($this->redirectTo);
        }

        // Eager load license to check status
        $user->load('license');
        Log::info('Checking license for user', [
            'user_id' => $user->id,
            'has_license' => $user->license ? 'yes' : 'no',
            'is_used' => $user->license ? $user->license->is_used : 'N/A',
            'expires_at' => $user->license && $user->license->expires_at ? $user->license->expires_at->toDateTimeString() : 'N/A',
            'is_future' => $user->license && $user->license->expires_at ? $user->license->expires_at->isFuture() : 'N/A',
        ]);

        // For all other authenticated users (non-superadmins), check their license status.
        if (!$user->hasActiveLicense()) {
            Log::warning('User login denied - no active license', ['user_id' => $user->id]);
            // Log out the user to prevent session issues
            Auth::logout();
            $request->session()->invalidate();
            $request->session()->regenerateToken();

            session()->flash('error', __('Your license is invalid or has expired. Please contact your administrator.'));
            return redirect()->route('login');
        }

        Log::info('User login successful with active license', ['user_id' => $user->id]);
        // If the user is a non-superadmin with an active license, or a superadmin,
        // proceed to the intended dashboard.
        return redirect($this->redirectTo);
    }

    /**
     * Log the user out of the application.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
     */
    public function logout(Request $request)
    {
        $this->guard()->logout();

        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect('/login');
    }
}

