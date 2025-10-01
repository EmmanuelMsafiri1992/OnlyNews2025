<!DOCTYPE HTML>
<html>
<head>
<meta charset="UTF-8">
<title>News</title>
<style>
body {
    margin:0;
    padding:0;
    background:#1a1a1a;
    color:#fff;
    font-family:Arial;
    font-size:24px;
    overflow:hidden;
}
.header {
    background:#2c3e50;
    padding:20px;
    text-align:center;
    border-bottom:3px solid #34495e;
}
.header h1 {
    font-size:48px;
    margin:5px 0;
    color:#fff;
    font-weight:bold;
}
.container {
    width:100%;
    height:100%;
    position:absolute;
    top:90px;
    bottom:70px;
}
.slider-area {
    float:left;
    width:70%;
    height:100%;
    background:#000;
    position:relative;
}
.sidebar {
    float:right;
    width:30%;
    height:100%;
    background:#2c3e50;
    overflow-y:auto;
    border-left:3px solid #34495e;
}
.slide {
    display:none;
    text-align:center;
    padding:20px;
    position:absolute;
    top:0;
    left:0;
    width:100%;
    height:100%;
}
.slide.active {
    display:block;
}
.slide img {
    max-width:90%;
    max-height:65%;
    height:auto;
    margin:10px auto;
    display:block;
}
.slide-info {
    padding:10px 20px;
    background:rgba(0,0,0,0.7);
    position:absolute;
    bottom:20px;
    left:20px;
    right:20px;
}
.slide h2 {
    font-size:36px;
    color:#fff;
    margin:10px 0;
    font-weight:bold;
}
.slide p {
    font-size:24px;
    color:#ddd;
    line-height:1.5;
    margin:10px 0;
}
.news-item {
    padding:20px;
    border-bottom:2px solid #34495e;
    background:#2c3e50;
}
.news-item.active {
    background:#3498db;
}
.news-item h3 {
    font-size:22px;
    color:#fff;
    margin:0 0 10px 0;
    font-weight:bold;
}
.news-item .date {
    font-size:16px;
    color:#bdc3c7;
    margin:5px 0 0 0;
}
.footer {
    background:#2c3e50;
    padding:15px;
    text-align:center;
    position:fixed;
    bottom:0;
    width:100%;
    font-size:18px;
    border-top:3px solid #34495e;
}
</style>
</head>
<body>

<div class="header">
<h1>{{ isset($settings['app_name']) ? $settings['app_name'] : 'School News' }}</h1>
</div>

<div class="container">
    <div class="slider-area">
        @if(isset($news) && count($news) > 0)
            @php $slideNum = 0; @endphp
            @foreach($news as $item)
                @if(isset($item->images) && count($item->images) > 0)
                    @foreach($item->images as $img)
                        <div class="slide @if($slideNum == 0) active @endif" data-time="{{ isset($img->slide_duration) ? $img->slide_duration : 5000 }}" data-news-id="{{ $item->id }}">
                            <img src="{{ asset('storage/' . $img->url) }}" alt="News">
                            <div class="slide-info">
                                <h2>{{ $item->title }}</h2>
                                <p>{{ strip_tags($item->description) }}</p>
                            </div>
                        </div>
                        @php $slideNum++; @endphp
                    @endforeach
                @else
                    <div class="slide @if($slideNum == 0) active @endif" data-time="5000" data-news-id="{{ $item->id }}">
                        <div class="slide-info">
                            <h2>{{ $item->title }}</h2>
                            <p>{{ strip_tags($item->description) }}</p>
                        </div>
                    </div>
                    @php $slideNum++; @endphp
                @endif
            @endforeach
        @else
            <div class="slide active">
                <h2>No news available</h2>
            </div>
        @endif
    </div>

    <div class="sidebar">
        @if(isset($news) && count($news) > 0)
            @php $itemNum = 0; @endphp
            @foreach($news as $item)
                <div class="news-item @if($itemNum == 0) active @endif" data-item-id="{{ $item->id }}">
                    <h3>{{ $item->title }}</h3>
                    <div class="date">{{ isset($item->created_at) ? date('M d, Y', strtotime($item->created_at)) : '' }}</div>
                </div>
                @php $itemNum++; @endphp
            @endforeach
        @endif
    </div>
</div>

<div class="footer">
{{ isset($settings['footer_copyright_text']) ? $settings['footer_copyright_text'] : 'Copyright 2025' }}
</div>

<script>
var slides = document.getElementsByClassName('slide');
var newsItems = document.getElementsByClassName('news-item');
var current = 0;

function show(n) {
    if (slides.length === 0) return;

    for (var i = 0; i < slides.length; i++) {
        slides[i].className = 'slide';
    }
    if (n >= slides.length) n = 0;
    if (n < 0) n = slides.length - 1;
    current = n;
    slides[current].className = 'slide active';

    // Highlight corresponding news item in sidebar
    var activeNewsId = slides[current].getAttribute('data-news-id');
    for (var j = 0; j < newsItems.length; j++) {
        var itemId = newsItems[j].getAttribute('data-item-id');
        if (itemId === activeNewsId) {
            newsItems[j].className = 'news-item active';
        } else {
            newsItems[j].className = 'news-item';
        }
    }

    var time = slides[current].getAttribute('data-time');
    setTimeout(function() { show(current + 1); }, time ? parseInt(time) : 5000);
}

if (slides.length > 0) show(0);

setTimeout(function() { location.reload(); }, 300000);
</script>

</body>
</html>
