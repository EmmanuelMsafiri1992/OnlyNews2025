<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">
    <meta http-equiv="Pragma" content="no-cache">
    <meta http-equiv="Expires" content="0">
    <title>{{ $settings['app_name'] ?? 'School News' }}</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif;
            background: #f9fafb;
            color: #1f2937;
            line-height: 1.6;
        }

        /* Header */
        .header {
            background: linear-gradient(135deg, #1e3a8a 0%, #3b82f6 100%);
            padding: 24px 48px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }

        .header-content {
            max-width: 1800px;
            margin: 0 auto;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .header h1 {
            font-size: 42px;
            font-weight: 700;
            color: #ffffff;
            text-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }

        .header-nav {
            display: flex;
            gap: 32px;
        }

        .header-nav a {
            color: #ffffff;
            text-decoration: none;
            font-size: 18px;
            font-weight: 500;
            opacity: 0.9;
            transition: opacity 0.2s;
        }

        .header-nav a:hover {
            opacity: 1;
        }

        /* Main Container */
        .main-container {
            max-width: 1800px;
            margin: 0 auto;
            padding: 48px;
        }

        .grid-container {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 48px;
            min-height: calc(100vh - 240px);
        }

        /* Card Styles */
        .card {
            background: #ffffff;
            border-radius: 16px;
            box-shadow: 0 10px 25px rgba(0, 0, 0, 0.08);
            overflow: hidden;
            transition: transform 0.3s, box-shadow 0.3s;
        }

        .card:hover {
            transform: translateY(-4px);
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.12);
        }

        /* Left Column - Slider */
        .slider-card {
            display: flex;
            flex-direction: column;
            position: relative;
        }

        .slide {
            display: none;
            flex-direction: column;
            height: 100%;
        }

        .slide.active {
            display: flex;
        }

        .slide-image-container {
            flex: 1;
            background: #f3f4f6;
            position: relative;
            overflow: hidden;
            min-height: 600px;
        }

        .slide-image {
            width: 100%;
            height: 100%;
            object-fit: cover;
        }

        .slide-info {
            position: absolute;
            bottom: 0;
            left: 0;
            right: 0;
            padding: 48px 32px 32px;
            background: linear-gradient(to top, rgba(0,0,0,0.8) 0%, rgba(0,0,0,0.4) 50%, transparent 100%);
        }

        .slide-title {
            font-size: 32px;
            font-weight: 700;
            color: #ffffff;
            margin-bottom: 12px;
            line-height: 1.2;
            text-shadow: 0 2px 4px rgba(0,0,0,0.5);
        }

        .slide-date {
            font-size: 16px;
            color: rgba(255,255,255,0.9);
            text-shadow: 0 1px 2px rgba(0,0,0,0.5);
        }

        /* Right Column - News List */
        .news-list {
            overflow-y: auto;
            max-height: calc(100vh - 240px);
        }

        .news-item {
            padding: 24px;
            border-bottom: 1px solid #e5e7eb;
            cursor: pointer;
            transition: background 0.2s;
        }

        .news-item:hover {
            background: #f9fafb;
        }

        .news-item.active {
            background: #eff6ff;
            border-left: 4px solid #3b82f6;
        }

        .news-item-title {
            font-size: 20px;
            font-weight: 600;
            color: #1f2937;
            margin-bottom: 8px;
            line-height: 1.4;
        }

        .news-item.active .news-item-title {
            color: #2563eb;
        }

        .news-item-meta {
            display: flex;
            gap: 16px;
            font-size: 14px;
            color: #6b7280;
        }

        .news-item-date,
        .news-item-category {
            display: flex;
            align-items: center;
            gap: 6px;
        }

        /* Footer */
        .footer {
            background: #1f2937;
            padding: 24px 48px;
            text-align: center;
            color: #9ca3af;
            font-size: 14px;
            margin-top: auto;
        }

        /* No News Message */
        .no-news {
            text-align: center;
            padding: 100px 48px;
            color: #9ca3af;
        }

        .no-news svg {
            width: 96px;
            height: 96px;
            margin: 0 auto 24px;
            opacity: 0.5;
        }

        .no-news h2 {
            font-size: 32px;
            color: #6b7280;
        }

        /* Scrollbar Styling */
        .news-list::-webkit-scrollbar {
            width: 8px;
        }

        .news-list::-webkit-scrollbar-track {
            background: #f3f4f6;
        }

        .news-list::-webkit-scrollbar-thumb {
            background: #d1d5db;
            border-radius: 4px;
        }

        .news-list::-webkit-scrollbar-thumb:hover {
            background: #9ca3af;
        }
    </style>
</head>
<body>
    <!-- Header -->
    <div class="header">
        <div class="header-content">
            <h1>{{ $settings['app_name'] ?? 'Welcome All' }}</h1>
            <div class="header-nav">
                <a href="/">Home</a>
                <a href="/login">Login</a>
            </div>
        </div>
    </div>

    <!-- Main Content -->
    <div class="main-container">
        @if(isset($news) && $news->count() > 0)
            <div class="grid-container">
                <!-- Left Column: Slider -->
                <div class="card slider-card">
                    @php $slideIndex = 0; @endphp
                    @foreach($news as $newsItem)
                        @if($newsItem->images->count() > 0)
                            @foreach($newsItem->images as $image)
                                <div class="slide {{ $slideIndex === 0 ? 'active' : '' }}"
                                     data-index="{{ $slideIndex }}"
                                     data-duration="{{ $image->slide_duration ?? 5000 }}"
                                     data-news-id="{{ $newsItem->id }}">
                                    <div class="slide-image-container">
                                        <img src="{{ asset('storage/' . $image->url) }}"
                                             alt="{{ strip_tags($newsItem->title) }}"
                                             class="slide-image">
                                        <div class="slide-info">
                                            <h2 class="slide-title">{{ strip_tags($newsItem->title) }}</h2>
                                            <div class="slide-date">{{ $newsItem->created_at->format('M d, Y') }}</div>
                                        </div>
                                    </div>
                                </div>
                                @php $slideIndex++; @endphp
                            @endforeach
                        @else
                            <div class="slide {{ $slideIndex === 0 ? 'active' : '' }}"
                                 data-index="{{ $slideIndex }}"
                                 data-duration="5000"
                                 data-news-id="{{ $newsItem->id }}">
                                <div class="slide-image-container" style="background: linear-gradient(135deg, #3b82f6 0%, #8b5cf6 100%); display: flex; align-items: center; justify-content: center;">
                                    <div style="text-align: center; padding: 48px; color: white;">
                                        <h2 class="slide-title" style="font-size: 48px; margin-bottom: 24px;">{{ strip_tags($newsItem->title) }}</h2>
                                        <div class="slide-date" style="font-size: 20px;">{{ $newsItem->created_at->format('M d, Y') }}</div>
                                    </div>
                                </div>
                            </div>
                            @php $slideIndex++; @endphp
                        @endif
                    @endforeach
                </div>

                <!-- Right Column: News List -->
                <div class="card">
                    <div class="news-list">
                        @php $itemIndex = 0; @endphp
                        @foreach($news as $newsItem)
                            <div class="news-item {{ $itemIndex === 0 ? 'active' : '' }}"
                                 data-news-id="{{ $newsItem->id }}"
                                 onclick="highlightNews({{ $newsItem->id }})">
                                <h3 class="news-item-title">{{ strip_tags($newsItem->title) }}</h3>
                                <div class="news-item-meta">
                                    <span class="news-item-date">📅 {{ $newsItem->created_at->format('M d, Y') }}</span>
                                    <span class="news-item-category">📂 {{ $newsItem->category->name ?? 'News' }}</span>
                                </div>
                            </div>
                            @php $itemIndex++; @endphp
                        @endforeach
                    </div>
                </div>
            </div>
        @else
            <div class="no-news">
                <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10a2 2 0 012 2v1m2 13a2 2 0 01-2-2V7m2 13a2 2 0 002-2V9a2 2 0 00-2-2h-2m-4-3H9M7 16h6M7 8h6v4H7V8z" />
                </svg>
                <h2>No news available at the moment</h2>
            </div>
        @endif
    </div>

    <!-- Footer -->
    <div class="footer">
        {{ $settings['footer_copyright_text'] ?? 'VCNS © 2025' }} | {{ $settings['footer_contact_info'] ?? 'Contact Us Now.' }}
    </div>

    <script>
        var currentSlideIndex = 0;
        var slides = document.querySelectorAll('.slide');
        var newsItems = document.querySelectorAll('.news-item');
        var autoSlideTimeout = null;

        function showSlide(index) {
            if (slides.length === 0) return;

            // Wrap around
            if (index >= slides.length) index = 0;
            if (index < 0) index = slides.length - 1;

            currentSlideIndex = index;

            // Hide all slides
            for (var i = 0; i < slides.length; i++) {
                slides[i].classList.remove('active');
            }

            // Show current slide
            slides[currentSlideIndex].classList.add('active');

            // Update news item highlights
            var currentNewsId = slides[currentSlideIndex].getAttribute('data-news-id');
            for (var j = 0; j < newsItems.length; j++) {
                if (newsItems[j].getAttribute('data-news-id') === currentNewsId) {
                    newsItems[j].classList.add('active');
                } else {
                    newsItems[j].classList.remove('active');
                }
            }

            // Start auto-slide
            startAutoSlide();
        }

        function startAutoSlide() {
            if (autoSlideTimeout) {
                clearTimeout(autoSlideTimeout);
            }

            var duration = parseInt(slides[currentSlideIndex].getAttribute('data-duration')) || 5000;

            autoSlideTimeout = setTimeout(function() {
                showSlide(currentSlideIndex + 1);
            }, duration);
        }

        function highlightNews(newsId) {
            // Find slide with matching news ID
            for (var i = 0; i < slides.length; i++) {
                if (slides[i].getAttribute('data-news-id') == newsId) {
                    showSlide(i);
                    break;
                }
            }
        }

        // Initialize
        if (slides.length > 0) {
            showSlide(0);
        }

        // Auto-refresh every 5 minutes
        setTimeout(function() {
            window.location.reload();
        }, 300000);
    </script>
</body>
</html>
