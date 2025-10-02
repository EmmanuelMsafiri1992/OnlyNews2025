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
            background: #2d3748;
            padding: 20px 48px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
        }

        .header-content {
            max-width: 1800px;
            margin: 0 auto;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .header h1 {
            font-size: 28px;
            font-weight: 400;
            color: #ffffff;
        }

        .header-nav {
            display: flex;
            gap: 32px;
        }

        .header-nav a {
            color: #cbd5e0;
            text-decoration: none;
            font-size: 16px;
            font-weight: 400;
        }

        /* Main Container */
        .main-container {
            max-width: 1800px;
            margin: 0 auto;
            padding: 48px;
        }

        .grid-container {
            width: 100%;
        }

        .left-column {
            float: left;
            width: 49%;
            margin-right: 1%;
        }

        .right-column {
            float: left;
            width: 49%;
            margin-left: 1%;
        }

        .clearfix:after {
            content: "";
            display: table;
            clear: both;
        }

        /* Card Styles */
        .card {
            background: #ffffff;
            border-radius: 12px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.15);
            overflow: hidden;
            height: 600px;
            position: relative;
        }

        /* Left Column - Slider */
        .slider-card {
            position: relative;
        }

        .slide {
            display: none;
            width: 100%;
            height: 100%;
            position: relative;
        }

        .slide.active {
            display: block;
        }

        .slide-image {
            width: 100%;
            height: 100%;
            object-fit: cover;
        }

        .slide-overlay {
            position: absolute;
            bottom: 0;
            left: 0;
            right: 0;
            padding: 60px 32px 24px;
            background: linear-gradient(to top, rgba(0,0,0,0.9) 0%, rgba(0,0,0,0.5) 70%, transparent 100%);
        }

        .slide-title {
            font-size: 28px;
            font-weight: 700;
            color: #ffffff;
            margin-bottom: 8px;
            line-height: 1.2;
            text-shadow: 0 2px 8px rgba(0,0,0,0.8);
        }

        .slide-date {
            font-size: 14px;
            color: rgba(255,255,255,0.95);
            text-shadow: 0 1px 3px rgba(0,0,0,0.8);
        }

        /* Navigation Arrows */
        .nav-arrow {
            position: absolute;
            top: 50%;
            transform: translateY(-50%);
            width: 48px;
            height: 48px;
            background: rgba(0,0,0,0.5);
            border: none;
            border-radius: 50%;
            color: white;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            z-index: 10;
        }

        .nav-arrow:hover {
            background: rgba(0,0,0,0.7);
        }

        .nav-arrow-left {
            left: 24px;
        }

        .nav-arrow-right {
            right: 24px;
        }

        .nav-arrow svg {
            width: 24px;
            height: 24px;
        }

        /* Navigation Dots */
        .nav-dots {
            position: absolute;
            bottom: 80px;
            left: 50%;
            transform: translateX(-50%);
            z-index: 10;
        }

        .nav-dot {
            width: 14px;
            height: 14px;
            border-radius: 50%;
            background: rgba(255,255,255,0.6);
            border: none;
            cursor: pointer;
            margin: 0 6px;
            display: inline-block;
        }

        .nav-dot.active {
            background: #ffffff;
        }

        /* Right Column - Content Card */
        .content-card {
            background: #3b82f6;
        }

        .content-header {
            padding: 32px;
            border-bottom: 1px solid rgba(255,255,255,0.3);
            background: #3b82f6;
        }

        .content-title {
            font-size: 36px;
            font-weight: 700;
            color: #ffffff;
            line-height: 1.3;
            text-align: right;
        }

        .content-body {
            padding: 32px;
            background: #2563eb;
            height: 488px;
            overflow-y: auto;
        }

        .content-meta {
            display: flex;
            align-items: center;
            gap: 16px;
            margin-bottom: 24px;
            flex-wrap: wrap;
        }

        .content-date {
            display: flex;
            align-items: center;
            gap: 8px;
            color: rgba(255,255,255,0.9);
            font-size: 14px;
        }

        .content-category {
            display: inline-block;
            padding: 6px 16px;
            background: #3b82f6;
            color: rgba(255,255,255,0.95);
            border-radius: 20px;
            font-size: 14px;
            font-weight: 500;
        }

        .content-description {
            color: rgba(255,255,255,0.9);
            font-size: 16px;
            line-height: 1.6;
        }

        /* Footer */
        .footer {
            background: #2d3748;
            padding: 24px 48px;
            text-align: center;
            color: #a0aec0;
            font-size: 14px;
            margin-top: 48px;
        }

        .footer-content {
            max-width: 1800px;
            margin: 0 auto;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        /* No Images Fallback */
        .no-image-slide {
            width: 100%;
            height: 100%;
            background: linear-gradient(135deg, #3b82f6 0%, #8b5cf6 100%);
            display: flex;
            align-items: center;
            justify-content: center;
            text-align: center;
            padding: 48px;
        }

        .no-image-content {
            color: white;
        }

        .no-image-title {
            font-size: 40px;
            font-weight: 700;
            margin-bottom: 16px;
            text-shadow: 0 2px 8px rgba(0,0,0,0.3);
        }

        .no-image-date {
            font-size: 18px;
            opacity: 0.95;
        }

        /* Scrollbar */
        .content-body::-webkit-scrollbar {
            width: 6px;
        }

        .content-body::-webkit-scrollbar-track {
            background: rgba(255,255,255,0.1);
        }

        .content-body::-webkit-scrollbar-thumb {
            background: rgba(255,255,255,0.3);
            border-radius: 3px;
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
            <div class="grid-container clearfix">
                <!-- Left Column: Image Slider -->
                <div class="left-column">
                <div class="card slider-card">
                    @php $slideIndex = 0; @endphp
                    @foreach($news as $newsItem)
                        @if($newsItem->images->count() > 0)
                            @foreach($newsItem->images as $image)
                                <div class="slide {{ $slideIndex === 0 ? 'active' : '' }}"
                                     data-index="{{ $slideIndex }}"
                                     data-duration="{{ $image->slide_duration ?? 5000 }}">
                                    <img src="{{ asset('storage/' . $image->url) }}"
                                         alt="{{ strip_tags($newsItem->title) }}"
                                         class="slide-image">
                                    <div class="slide-overlay">
                                        <h2 class="slide-title">{{ strip_tags($newsItem->title) }}</h2>
                                        <div class="slide-date">{{ $newsItem->created_at->format('M d, Y') }}</div>
                                    </div>
                                </div>
                                @php $slideIndex++; @endphp
                            @endforeach
                        @else
                            <div class="slide {{ $slideIndex === 0 ? 'active' : '' }}"
                                 data-index="{{ $slideIndex }}"
                                 data-duration="5000">
                                <div class="no-image-slide">
                                    <div class="no-image-content">
                                        <h2 class="no-image-title">{{ strip_tags($newsItem->title) }}</h2>
                                        <div class="no-image-date">{{ $newsItem->created_at->format('M d, Y') }}</div>
                                    </div>
                                </div>
                            </div>
                            @php $slideIndex++; @endphp
                        @endif
                    @endforeach

                    <!-- Navigation Arrows -->
                    @if($slideIndex > 1)
                        <button class="nav-arrow nav-arrow-left" onclick="previousSlide()">
                            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"></path>
                            </svg>
                        </button>
                        <button class="nav-arrow nav-arrow-right" onclick="nextSlide()">
                            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path>
                            </svg>
                        </button>

                        <!-- Navigation Dots -->
                        <div class="nav-dots">
                            @for($i = 0; $i < $slideIndex; $i++)
                                <button class="nav-dot {{ $i === 0 ? 'active' : '' }}" onclick="goToSlide({{ $i }})"></button>
                            @endfor
                        </div>
                    @endif
                </div>
                </div>

                <!-- Right Column: Content Card -->
                <div class="right-column">
                <div class="card content-card">
                    @php
                        $currentIndex = 0;
                        $currentItem = $news->first();
                    @endphp
                    <div class="content-header">
                        <h2 class="content-title" id="content-title">{{ strip_tags($currentItem->title) }}</h2>
                    </div>
                    <div class="content-body">
                        <div class="content-meta" id="content-meta">
                            <div class="content-date">
                                <svg width="16" height="16" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                                </svg>
                                <span id="content-date">{{ $currentItem->created_at->format('M d, Y') }}</span>
                            </div>
                            <div class="content-category" id="content-category">{{ $currentItem->category->name ?? 'חוקים' }}</div>
                        </div>
                        <div class="content-description" id="content-description">
                            {!! nl2br(e(strip_tags($currentItem->description))) !!}
                        </div>
                    </div>
                </div>
                </div>
            </div>
        @else
            <div style="text-align: center; padding: 100px;">
                <h2 style="color: #6b7280; font-size: 32px;">No news available</h2>
            </div>
        @endif
    </div>

    <!-- Footer -->
    <div class="footer">
        <div class="footer-content">
            <div>{{ $settings['footer_copyright_text'] ?? 'VCNS © 2025' }}</div>
            <div>{{ $settings['footer_contact_info'] ?? 'Contact Us Now.' }}</div>
            <div>
                <a href="/" style="color: #cbd5e0; text-decoration: none; margin-right: 24px;">Home</a>
                <a href="/login" style="color: #cbd5e0; text-decoration: none;">Login</a>
            </div>
        </div>
    </div>

    <script>
        // Store all news data for content updates
        var newsData = [
            @foreach($news as $item)
                {
                    title: {!! json_encode(strip_tags($item->title)) !!},
                    date: "{{ $item->created_at->format('M d, Y') }}",
                    category: "{{ $item->category->name ?? 'חוקים' }}",
                    description: {!! json_encode(nl2br(e(strip_tags($item->description)))) !!}
                },
            @endforeach
        ];

        var currentSlideIndex = 0;
        var slides = document.querySelectorAll('.slide');
        var dots = document.querySelectorAll('.nav-dot');
        var autoSlideTimeout = null;

        function updateContent(index) {
            // Find which news item this slide belongs to
            var newsIndex = 0;
            var slideCount = 0;

            @php $newsIndex = 0; $slideCount = 0; @endphp
            @foreach($news as $item)
                @if($item->images->count() > 0)
                    @foreach($item->images as $image)
                        if (slideCount === index) {
                            newsIndex = {{ $newsIndex }};
                        }
                        slideCount++;
                    @endforeach
                @else
                    if (slideCount === index) {
                        newsIndex = {{ $newsIndex }};
                    }
                    slideCount++;
                @endif
                @php $newsIndex++; @endphp
            @endforeach

            if (newsData[newsIndex]) {
                document.getElementById('content-title').textContent = newsData[newsIndex].title;
                document.getElementById('content-date').textContent = newsData[newsIndex].date;
                document.getElementById('content-category').textContent = newsData[newsIndex].category;
                document.getElementById('content-description').innerHTML = newsData[newsIndex].description;
            }
        }

        function showSlide(index) {
            if (slides.length === 0) return;

            if (index >= slides.length) index = 0;
            if (index < 0) index = slides.length - 1;

            currentSlideIndex = index;

            // Update slides
            for (var i = 0; i < slides.length; i++) {
                slides[i].classList.remove('active');
            }
            slides[currentSlideIndex].classList.add('active');

            // Update dots
            for (var j = 0; j < dots.length; j++) {
                dots[j].classList.remove('active');
            }
            if (dots[currentSlideIndex]) {
                dots[currentSlideIndex].classList.add('active');
            }

            // Update content card
            updateContent(currentSlideIndex);

            // Restart auto-slide
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

        function previousSlide() {
            showSlide(currentSlideIndex - 1);
        }

        function nextSlide() {
            showSlide(currentSlideIndex + 1);
        }

        function goToSlide(index) {
            showSlide(index);
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
