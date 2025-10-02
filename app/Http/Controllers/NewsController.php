<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\News;
use Illuminate\Support\Facades\Log;

class NewsController extends Controller
{
    public function index(Request $request)
    {
        // Get user agent for detection
        $userAgent = strtolower($request->header('User-Agent', ''));

        // Log the user agent for debugging
        Log::info('Browser accessing app', ['user_agent' => $userAgent]);

        // Check for old Chrome/Chromium versions
        $chromeVersion = 999;
        if (preg_match('/chrome\/([0-9]+)/i', $userAgent, $matches)) {
            $chromeVersion = (int)$matches[1];
        } elseif (preg_match('/chromium\/([0-9]+)/i', $userAgent, $matches)) {
            $chromeVersion = (int)$matches[1];
        }

        // Comprehensive TV and old browser detection
        $isOldBrowser = (
            // Old Chrome/Chromium (< 60 is too old for modern JS)
            $chromeVersion < 60 ||
            // TV platforms
            stripos($userAgent, 'tizen') !== false ||
            stripos($userAgent, 'webos') !== false ||
            stripos($userAgent, 'netcast') !== false ||
            stripos($userAgent, 'smarttv') !== false ||
            stripos($userAgent, 'smart-tv') !== false ||
            stripos($userAgent, 'googletv') !== false ||
            stripos($userAgent, 'appletv') !== false ||
            stripos($userAgent, 'hbbtv') !== false ||
            stripos($userAgent, 'maple') !== false ||
            stripos($userAgent, 'sonydtv') !== false ||
            stripos($userAgent, 'viera') !== false ||
            // TV brands
            stripos($userAgent, 'samsung') !== false ||
            stripos($userAgent, 'lg') !== false ||
            stripos($userAgent, 'philips') !== false ||
            stripos($userAgent, 'sharp') !== false ||
            stripos($userAgent, 'panasonic') !== false ||
            stripos($userAgent, 'sony') !== false ||
            stripos($userAgent, 'vizio') !== false ||
            // Old browsers
            stripos($userAgent, 'msie') !== false ||
            stripos($userAgent, 'trident') !== false ||
            // Opera TV/Mini
            (stripos($userAgent, 'opera') !== false && (stripos($userAgent, 'tv') !== false || stripos($userAgent, 'mini') !== false))
        );

        // Force simple mode with ?simple=1 or ?legacy=1 parameter, OR if detected as old browser
        if ($isOldBrowser || $request->get('legacy') === '1' || $request->get('simple') === '1') {
            try {
                // Serve simple server-rendered page for old browsers/TVs
                $news = News::with('category', 'images')->get();
                $settings = \App\Models\Setting::pluck('value', 'key')->toArray();

                Log::info('Serving simple TV view', [
                    'user_agent' => $userAgent,
                    'is_old_browser' => $isOldBrowser,
                    'news_count' => $news->count(),
                    'settings_count' => count($settings)
                ]);

                return response()
                    ->view('news.tv', compact('news', 'settings'))
                    ->header('Cache-Control', 'no-cache, no-store, must-revalidate')
                    ->header('Pragma', 'no-cache')
                    ->header('Expires', '0');
            } catch (\Exception $e) {
                Log::error('Error serving simple view', ['error' => $e->getMessage(), 'trace' => $e->getTraceAsString()]);
                return response('<h1>Error loading page</h1><p>' . $e->getMessage() . '</p>', 500);
            }
        }

        // Regular Vue app for modern browsers
        Log::info('Serving Vue app for modern browser');
        return view('layouts.app');
    }

    // public function apiIndex()
    // {
    //     try {
    //         $news = News::with('category')->get();
    //         if ($news->isEmpty()) {
    //             Log::info('No news records found in the database.');
    //             return response()->json([
    //                 'success' => true,
    //                 'data' => []
    //             ]);
    //         }
    //         return response()->json([
    //             'success' => true,
    //             'data' => $news->map(function ($item) {
    //                 return [
    //                     'id' => $item->id,
    //                     'image_url' => $item->image ? asset('storage/' . $item->image) : null,
    //                     'title' => $item->title ?? 'No Title',
    //                     'description' => $item->description ?? 'No Description',
    //                     'full_description' => $item->description ?? 'No Description', // Assuming full_description is the same as description
    //                     'date' => $item->created_at ? $item->created_at->format('M d, Y') : null,
    //                     'status' => $item->status ?? 'draft',
    //                     'category' => $item->category ? $item->category->name : 'Uncategorized',
    //                 ];
    //             })
    //         ]);
    //     } catch (\Exception $e) {
    //         Log::error('Error in apiIndex: ' . $e->getMessage());
    //         return response()->json([
    //             'success' => false,
    //             'message' => 'An error occurred while fetching news.',
    //             'error' => $e->getMessage()
    //         ], 500);
    //     }
    // }
//     public function apiIndex()
// {
//     try {
//         $news = News::with('category', 'images')->get(); // Load images relationship

//         if ($news->isEmpty()) {
//             Log::info('No news records found in the database.');
//             return response()->json([
//                 'success' => true,
//                 'data' => []
//             ]);
//         }

//         return response()->json([
//             'success' => true,
//             'data' => $news->map(function ($item) {
//                 return [
//                     'id' => $item->id,
//                     // Get the first image from the images relationship
//                     'image_url' => $item->images->isNotEmpty()
//                         ? asset('storage/' . $item->images->first()->url)
//                         : null,
//                     'title' => $item->title ?? 'No Title',
//                     'description' => $item->description ?? 'No Description',
//                     'full_description' => $item->description ?? 'No Description',
//                     'date' => $item->created_at ? $item->created_at->format('M d, Y') : null,
//                     'status' => $item->status ?? 'draft',
//                     'category' => $item->category ? $item->category->name : 'Uncategorized',
//                     // Optional: include all images if needed
//                     'all_images' => $item->images->map(function($img) {
//                         return asset('storage/' . $img->url);
//                     }),
//                 ];
//             })
//         ]);
//     } catch (\Exception $e) {
//         Log::error('Error in apiIndex: ' . $e->getMessage());
//         return response()->json([
//             'success' => false,
//             'message' => 'An error occurred while fetching news.',
//             'error' => $e->getMessage()
//         ], 500);
//     }
// }
// public function apiIndex()
// {
//     try {
//         $news = News::with('category', 'images')->get();

//         // Debug logging
//         Log::info('News count: ' . $news->count());
//         foreach ($news as $item) {
//             Log::info('News ID: ' . $item->id . ', Images count: ' . $item->images->count());
//             foreach ($item->images as $image) {
//                 Log::info('Image URL: ' . $image->url);
//                 Log::info('Full asset URL: ' . asset('storage/' . $image->url));
//             }
//         }

//         if ($news->isEmpty()) {
//             return response()->json(['success' => true, 'data' => []]);
//         }

//         return response()->json([
//             'success' => true,
//             'data' => $news->map(function ($item) {
//                 $imageUrl = null;
//                 if ($item->images->isNotEmpty()) {
//                     $imageUrl = asset('storage/' . $item->images->first()->url);
//                 }

//                 return [
//                     'id' => $item->id,
//                     'image_url' => $imageUrl,
//                     'title' => $item->title ?? 'No Title',
//                     'description' => $item->description ?? 'No Description',
//                     'full_description' => $item->description ?? 'No Description',
//                     'date' => $item->created_at ? $item->created_at->format('M d, Y') : null,
//                     'status' => $item->status ?? 'draft',
//                     'category' => $item->category ? $item->category->name : 'Uncategorized',
//                     // Debug info - remove this later
//                     'debug_images_count' => $item->images->count(),
//                     'debug_raw_image_path' => $item->images->first()->url ?? null,
//                 ];
//             })
//         ]);
//     } catch (\Exception $e) {
//         Log::error('Error in apiIndex: ' . $e->getMessage());
//         return response()->json([
//             'success' => false,
//             'message' => 'An error occurred while fetching news.',
//             'error' => $e->getMessage()
//         ], 500);
//     }
// }
public function apiIndex()
{
    try {
        $news = News::with('category', 'images')->get();

        $slides = [];

        foreach ($news as $item) {
            if ($item->images->isNotEmpty()) {
                // Create a slide for each image
                foreach ($item->images as $image) {
                    $slides[] = [
                        'id' => $item->id . '_' . $image->id, // Unique ID
                        'news_id' => $item->id,
                        'image_url' => asset('storage/' . $image->url),
                        'title' => $item->title ?? 'No Title',
                        'description' => $item->description ?? 'No Description',
                        'full_description' => $item->description ?? 'No Description',
                        'date' => $item->created_at ? $item->created_at->format('M d, Y') : null,
                        'status' => $item->status ?? 'draft',
                        'category' => $item->category ? $item->category->name : 'Uncategorized',
                        'slide_duration' => $image->slide_duration ?? 5000, // Include slide duration
                    ];
                }
            } else {
                // News with no images - use placeholder or skip
                $slides[] = [
                    'id' => $item->id,
                    'news_id' => $item->id,
                    'image_url' => '',
                    'title' => $item->title ?? 'No Title',
                    'description' => $item->description ?? 'No Description',
                    'full_description' => $item->description ?? 'No Description',
                    'date' => $item->created_at ? $item->created_at->format('M d, Y') : null,
                    'status' => $item->status ?? 'draft',
                    'category' => $item->category ? $item->category->name : 'Uncategorized',
                    'slide_duration' => 5000, // Default duration for items without images
                ];
            }
        }

        return response()->json([
            'success' => true,
            'data' => $slides
        ]);

    } catch (\Exception $e) {
        Log::error('Error in apiIndex: ' . $e->getMessage());
        return response()->json([
            'success' => false,
            'message' => 'An error occurred while fetching news.',
            'error' => $e->getMessage()
        ], 500);
    }
}
}
