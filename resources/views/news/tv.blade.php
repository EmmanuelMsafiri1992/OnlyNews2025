<!DOCTYPE html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>News</title>
<style>
* { margin:0; padding:0; }
body { font-family:Arial; background:#0f172a; color:#fff; overflow:hidden; }
.header { background:#1e293b; padding:25px; text-align:center; border-bottom:4px solid #3b82f6; }
.header h1 { font-size:48px; color:#fff; margin:0; font-weight:bold; }
.main { width:100%; position:absolute; top:110px; bottom:70px; }
.slider-section { float:left; width:70%; height:100%; background:#000; position:relative; }
.sidebar-section { float:right; width:30%; height:100%; background:#1e293b; border-left:3px solid #3b82f6; overflow-y:auto; }
.slide { display:none; position:absolute; width:100%; height:100%; }
.slide.active { display:block; }
.slide img { width:100%; height:70%; object-fit:contain; background:#000; }
.slide-text { position:absolute; bottom:0; width:100%; background:#1e293b; padding:25px; border-top:3px solid #3b82f6; }
.slide-text h2 { font-size:36px; color:#fff; margin:0 0 15px 0; font-weight:bold; }
.slide-text p { font-size:22px; color:#cbd5e1; line-height:1.5; margin:0; }
.news-item { padding:20px; border-bottom:2px solid #334155; }
.news-item.active { background:#3b82f6; border-left:5px solid #60a5fa; }
.news-item h3 { font-size:20px; color:#fff; margin:0 0 8px 0; font-weight:bold; }
.news-item .date { font-size:14px; color:#94a3b8; }
.footer { background:#1e293b; padding:18px; text-align:center; font-size:16px; border-top:4px solid #3b82f6; color:#cbd5e1; position:fixed; bottom:0; width:100%; }
</style>
</head>
<body>

<div class="header">
<h1>{{ $settings['app_name'] ?? 'School News' }}</h1>
</div>

<div class="main">
<div class="slider-section">
@if($news->count() > 0)
    @php $slideNum = 0; @endphp
    @foreach($news as $item)
        @if($item->images->count() > 0)
            @foreach($item->images as $img)
                <div class="slide {{ $slideNum == 0 ? 'active' : '' }}" data-time="{{ $img->slide_duration ?? 5000 }}" data-news-id="{{ $item->id }}">
                    <img src="{{ asset('storage/' . $img->url) }}" alt="">
                    <div class="slide-text">
                        <h2>{{ $item->title }}</h2>
                        <p>{!! nl2br(e(strip_tags($item->description))) !!}</p>
                    </div>
                </div>
                @php $slideNum++; @endphp
            @endforeach
        @else
            <div class="slide {{ $slideNum == 0 ? 'active' : '' }}" data-time="5000" data-news-id="{{ $item->id }}">
                <div class="slide-text" style="position:relative; height:100%; padding-top:200px;">
                    <h2>{{ $item->title }}</h2>
                    <p>{!! nl2br(e(strip_tags($item->description))) !!}</p>
                </div>
            </div>
            @php $slideNum++; @endphp
        @endif
    @endforeach
@else
    <div class="slide active">
        <div class="slide-text" style="text-align:center; padding:100px 20px;">
            <h2>No news available</h2>
        </div>
    </div>
@endif
</div>

<div class="sidebar-section">
@if($news->count() > 0)
    @php $itemNum = 0; @endphp
    @foreach($news as $item)
        <div class="news-item {{ $itemNum == 0 ? 'active' : '' }}" data-item-id="{{ $item->id }}">
            <h3>{{ $item->title }}</h3>
            <div class="date">{{ $item->created_at->format('M d, Y') }}</div>
        </div>
        @php $itemNum++; @endphp
    @endforeach
@endif
</div>
</div>

<div class="footer">
{{ $settings['footer_copyright_text'] ?? 'Copyright 2025' }}
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
    current = n;
    slides[current].className = 'slide active';

    var activeNewsId = slides[current].getAttribute('data-news-id');
    for (var j = 0; j < newsItems.length; j++) {
        if (newsItems[j].getAttribute('data-item-id') === activeNewsId) {
            newsItems[j].className = 'news-item active';
        } else {
            newsItems[j].className = 'news-item';
        }
    }

    var time = slides[current].getAttribute('data-time');
    setTimeout(function() { show(current + 1); }, parseInt(time) || 5000);
}

if (slides.length > 0) show(0);
setTimeout(function() { location.reload(); }, 300000);
</script>

</body>
</html>
