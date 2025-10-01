<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">
    <meta http-equiv="Pragma" content="no-cache">
    <meta http-equiv="Expires" content="0">
    <title>{{ $settings['app_name'] ?? 'News' }}</title>
    <style type="text/css">
        body {
            margin: 0;
            padding: 0;
            font-family: Arial, sans-serif;
            background-color: #000000;
            color: #ffffff;
        }

        .header {
            background-color: #1a1a1a;
            padding: 30px;
            text-align: center;
            border-bottom: 3px solid #444;
        }

        .header h1 {
            font-size: 48px;
            margin: 0 0 10px 0;
            color: #ffffff;
        }

        .header p {
            font-size: 24px;
            margin: 0;
            color: #cccccc;
        }

        .slide {
            display: none;
            text-align: center;
            padding: 20px;
        }

        .slide.active {
            display: block;
        }

        .slide-image {
            width: 90%;
            max-width: 1400px;
            height: auto;
            margin: 20px auto;
            display: block;
            background-color: #000;
        }

        .slide-content {
            max-width: 1400px;
            margin: 20px auto;
            padding: 30px;
            background-color: #1a1a1a;
            border: 2px solid #444;
        }

        .slide-title {
            font-size: 42px;
            margin: 0 0 20px 0;
            color: #ffffff;
            font-weight: bold;
        }

        .slide-description {
            font-size: 28px;
            color: #cccccc;
            line-height: 1.6;
            text-align: left;
        }

        .footer {
            background-color: #1a1a1a;
            padding: 20px;
            text-align: center;
            font-size: 20px;
            border-top: 3px solid #444;
            position: fixed;
            bottom: 0;
            width: 100%;
        }

        .no-news {
            text-align: center;
            padding: 100px 20px;
            font-size: 48px;
            color: #666;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>{{ $settings['app_name'] ?? 'School News' }}</h1>
        <p>{{ $settings['header_title'] ?? 'Welcome' }}</p>
    </div>

    @if($news->count() > 0)
        <div id="slider">
            @php
                $slideIndex = 0;
            @endphp
            @foreach($news as $newsItem)
                @if($newsItem->images->count() > 0)
                    @foreach($newsItem->images as $image)
                        <div class="slide {{ $slideIndex === 0 ? 'active' : '' }}" id="slide{{ $slideIndex }}" data-duration="{{ $image->slide_duration ?? 5000 }}">
                            <img src="{{ asset('storage/' . $image->url) }}" alt="{{ $newsItem->title }}" class="slide-image">
                            <div class="slide-content">
                                <h2 class="slide-title">{{ $newsItem->title }}</h2>
                                <div class="slide-description">{!! nl2br(strip_tags($newsItem->description)) !!}</div>
                            </div>
                        </div>
                        @php $slideIndex++; @endphp
                    @endforeach
                @else
                    <div class="slide {{ $slideIndex === 0 ? 'active' : '' }}" id="slide{{ $slideIndex }}" data-duration="5000">
                        <div class="slide-content">
                            <h2 class="slide-title">{{ $newsItem->title }}</h2>
                            <div class="slide-description">{!! nl2br(strip_tags($newsItem->description)) !!}</div>
                        </div>
                    </div>
                    @php $slideIndex++; @endphp
                @endif
            @endforeach
        </div>
    @else
        <div class="no-news">No news available</div>
    @endif

    <div class="footer">
        {{ $settings['footer_copyright_text'] ?? '© 2025' }} | {{ $settings['footer_contact_info'] ?? 'Contact Us' }}
    </div>

    <script type="text/javascript">
        var currentSlide = 0;
        var slides = document.getElementsByClassName('slide');
        var autoSlideTimeout = null;

        function removeClass(element, className) {
            if (element.className) {
                element.className = element.className.replace(new RegExp('\\b' + className + '\\b', 'g'), '').replace(/\s+/g, ' ').replace(/^\s+|\s+$/g, '');
            }
        }

        function addClass(element, className) {
            if (element.className.indexOf(className) === -1) {
                element.className = element.className + ' ' + className;
            }
        }

        function showSlide(index) {
            if (slides.length === 0) return;

            if (index >= slides.length) index = 0;
            if (index < 0) index = slides.length - 1;

            currentSlide = index;

            for (var i = 0; i < slides.length; i++) {
                removeClass(slides[i], 'active');
            }
            addClass(slides[currentSlide], 'active');

            startAutoSlide();
        }

        function startAutoSlide() {
            if (autoSlideTimeout) {
                clearTimeout(autoSlideTimeout);
            }

            var durationAttr = slides[currentSlide].getAttribute('data-duration');
            var duration = durationAttr ? parseInt(durationAttr, 10) : 5000;

            autoSlideTimeout = setTimeout(function() {
                showSlide(currentSlide + 1);
            }, duration);
        }

        if (slides.length > 0) {
            startAutoSlide();
        }

        setTimeout(function() {
            window.location.reload();
        }, 300000);
    </script>
</body>
</html>
