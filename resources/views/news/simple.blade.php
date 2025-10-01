<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">
    <meta http-equiv="Pragma" content="no-cache">
    <meta http-equiv="Expires" content="0">
    <title>{{ $settings['app_name'] ?? 'News' }}</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: Arial, sans-serif;
            background: #f5f5f5;
            overflow: hidden;
        }

        .header {
            background: #2c3e50;
            color: white;
            padding: 20px;
            text-align: center;
        }

        .header h1 {
            font-size: 2.5rem;
            margin-bottom: 10px;
        }

        .container {
            display: flex;
            height: calc(100vh - 140px);
            padding: 20px;
            gap: 20px;
        }

        .slider {
            flex: 1;
            background: white;
            border-radius: 10px;
            overflow: hidden;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }

        .slide {
            display: none;
            width: 100%;
            height: 100%;
        }

        .slide.active {
            display: flex;
            flex-direction: column;
        }

        .slide-image {
            width: 100%;
            height: 70%;
            object-fit: contain;
            background: #000;
        }

        .slide-content {
            padding: 20px;
            height: 30%;
            overflow: auto;
        }

        .slide-title {
            font-size: 1.8rem;
            margin-bottom: 10px;
            color: #2c3e50;
        }

        .slide-description {
            font-size: 1.2rem;
            color: #666;
            line-height: 1.6;
        }

        .news-list {
            flex: 0 0 400px;
            background: white;
            border-radius: 10px;
            overflow-y: auto;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }

        .news-item {
            padding: 15px;
            border-bottom: 1px solid #eee;
            cursor: pointer;
            transition: background 0.3s;
        }

        .news-item:hover,
        .news-item.active {
            background: #e3f2fd;
        }

        .news-item-title {
            font-size: 1.1rem;
            font-weight: bold;
            margin-bottom: 5px;
            color: #2c3e50;
        }

        .news-item-date {
            font-size: 0.9rem;
            color: #999;
        }

        .footer {
            background: #2c3e50;
            color: white;
            padding: 10px 20px;
            text-align: center;
            font-size: 0.9rem;
        }

        .no-news {
            display: flex;
            align-items: center;
            justify-content: center;
            height: 100%;
            font-size: 2rem;
            color: #999;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>{{ $settings['app_name'] ?? 'School News' }}</h1>
        <p>{{ $settings['header_title'] ?? 'Welcome' }}</p>
    </div>

    @if($news->count() > 0)
        <div class="container">
            <!-- Slider -->
            <div class="slider" id="slider">
                @php
                    $slideIndex = 0;
                @endphp
                @foreach($news as $newsItem)
                    @if($newsItem->images->count() > 0)
                        @foreach($newsItem->images as $image)
                            <div class="slide {{ $slideIndex === 0 ? 'active' : '' }}" data-duration="{{ $image->slide_duration ?? 5000 }}">
                                <img src="{{ asset('storage/' . $image->url) }}" alt="{{ $newsItem->title }}" class="slide-image">
                                <div class="slide-content">
                                    <h2 class="slide-title">{{ $newsItem->title }}</h2>
                                    <div class="slide-description">{!! strip_tags($newsItem->description) !!}</div>
                                </div>
                            </div>
                            @php $slideIndex++; @endphp
                        @endforeach
                    @else
                        <div class="slide {{ $slideIndex === 0 ? 'active' : '' }}" data-duration="5000">
                            <div style="width: 100%; height: 70%; background: #ddd; display: flex; align-items: center; justify-content: center; color: #999; font-size: 2rem;">
                                No Image
                            </div>
                            <div class="slide-content">
                                <h2 class="slide-title">{{ $newsItem->title }}</h2>
                                <div class="slide-description">{!! strip_tags($newsItem->description) !!}</div>
                            </div>
                        </div>
                        @php $slideIndex++; @endphp
                    @endif
                @endforeach
            </div>

            <!-- News List -->
            <div class="news-list">
                @php $itemIndex = 0; @endphp
                @foreach($news as $newsItem)
                    <div class="news-item {{ $itemIndex === 0 ? 'active' : '' }}" onclick="goToSlide({{ $itemIndex }})">
                        <div class="news-item-title">{{ $newsItem->title }}</div>
                        <div class="news-item-date">{{ $newsItem->created_at->format('M d, Y') }}</div>
                    </div>
                    @php $itemIndex++; @endphp
                @endforeach
            </div>
        </div>
    @else
        <div class="container">
            <div class="no-news">No news available</div>
        </div>
    @endif

    <div class="footer">
        {{ $settings['footer_copyright_text'] ?? '© 2025' }} | {{ $settings['footer_contact_info'] ?? 'Contact Us' }}
    </div>

    <script>
        var currentSlide = 0;
        var slides = document.querySelectorAll('.slide');
        var newsItems = document.querySelectorAll('.news-item');
        var autoSlideTimeout;

        function showSlide(index) {
            if (slides.length === 0) return;

            // Wrap around
            if (index >= slides.length) index = 0;
            if (index < 0) index = slides.length - 1;

            currentSlide = index;

            // Update slides
            for (var i = 0; i < slides.length; i++) {
                slides[i].classList.remove('active');
            }
            slides[currentSlide].classList.add('active');

            // Update news list
            for (var i = 0; i < newsItems.length; i++) {
                newsItems[i].classList.remove('active');
            }
            if (newsItems[currentSlide]) {
                newsItems[currentSlide].classList.add('active');
            }

            // Auto advance
            startAutoSlide();
        }

        function startAutoSlide() {
            if (autoSlideTimeout) {
                clearTimeout(autoSlideTimeout);
            }

            var duration = parseInt(slides[currentSlide].getAttribute('data-duration')) || 5000;
            autoSlideTimeout = setTimeout(function() {
                showSlide(currentSlide + 1);
            }, duration);
        }

        function goToSlide(index) {
            showSlide(index);
        }

        // Start auto slide
        if (slides.length > 0) {
            startAutoSlide();
        }

        // Refresh page every 5 minutes to get new content
        setTimeout(function() {
            window.location.reload();
        }, 5 * 60 * 1000);
    </script>
</body>
</html>
