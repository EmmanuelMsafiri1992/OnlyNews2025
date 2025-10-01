<!DOCTYPE HTML>
<html>
<head>
<meta charset="UTF-8">
<title>News</title>
<style>
body { margin:0; padding:0; background:#000; color:#fff; font-family:Arial; font-size:24px; }
.header { background:#222; padding:20px; text-align:center; }
.header h1 { font-size:48px; margin:10px 0; color:#fff; }
.slide { display:none; text-align:center; padding:20px; min-height:400px; }
.slide.active { display:block; }
.slide img { max-width:90%; height:auto; margin:20px auto; display:block; }
.slide h2 { font-size:36px; color:#fff; margin:20px 0; }
.slide p { font-size:24px; color:#ccc; line-height:1.5; max-width:1200px; margin:10px auto; }
.footer { background:#222; padding:15px; text-align:center; position:fixed; bottom:0; width:100%; }
</style>
</head>
<body>

<div class="header">
<h1>{{ isset($settings['app_name']) ? $settings['app_name'] : 'School News' }}</h1>
</div>

@if(isset($news) && count($news) > 0)
    @php $slideNum = 0; @endphp
    @foreach($news as $item)
        @if(isset($item->images) && count($item->images) > 0)
            @foreach($item->images as $img)
                <div class="slide @if($slideNum == 0) active @endif" data-time="{{ isset($img->slide_duration) ? $img->slide_duration : 5000 }}">
                    <img src="{{ asset('storage/' . $img->url) }}" alt="News">
                    <h2>{{ $item->title }}</h2>
                    <p>{{ strip_tags($item->description) }}</p>
                </div>
                @php $slideNum++; @endphp
            @endforeach
        @else
            <div class="slide @if($slideNum == 0) active @endif" data-time="5000">
                <h2>{{ $item->title }}</h2>
                <p>{{ strip_tags($item->description) }}</p>
            </div>
            @php $slideNum++; @endphp
        @endif
    @endforeach
@else
    <div class="slide active">
        <h2>No news available</h2>
    </div>
@endif

<div class="footer">
{{ isset($settings['footer_copyright_text']) ? $settings['footer_copyright_text'] : 'Copyright 2025' }}
</div>

<script>
var slides = document.getElementsByClassName('slide');
var current = 0;

function show(n) {
    for (var i = 0; i < slides.length; i++) {
        slides[i].className = 'slide';
    }
    if (n >= slides.length) n = 0;
    if (n < 0) n = slides.length - 1;
    current = n;
    slides[current].className = 'slide active';

    var time = slides[current].getAttribute('data-time');
    setTimeout(function() { show(current + 1); }, time ? parseInt(time) : 5000);
}

if (slides.length > 0) show(0);

setTimeout(function() { location.reload(); }, 300000);
</script>

</body>
</html>
