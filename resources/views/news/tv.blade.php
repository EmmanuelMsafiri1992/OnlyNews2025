<!DOCTYPE html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>News TV</title>
<style>
* { margin:0; padding:0; }
body { font-family:Arial,sans-serif; background:#000; color:#fff; overflow:hidden; }
.header { background:#1e3a5f; padding:20px; text-align:center; border-bottom:3px solid #2563eb; }
.header h1 { font-size:42px; color:#fff; margin:0; font-weight:bold; }
.container { width:100%; height:calc(100vh - 140px); display:table; }
.left { display:table-cell; width:70%; background:#000; vertical-align:top; position:relative; }
.right { display:table-cell; width:30%; background:#1e293b; vertical-align:top; border-left:3px solid #2563eb; overflow-y:auto; }
.slide { display:none; width:100%; height:100%; text-align:center; }
.slide.active { display:block; }
.slide img { max-width:95%; max-height:75vh; margin:20px auto; display:block; }
.info { position:absolute; bottom:0; left:0; right:0; background:rgba(30,58,95,0.95); padding:20px; border-top:3px solid #2563eb; }
.info h2 { font-size:32px; color:#fff; margin:0 0 10px 0; }
.info p { font-size:20px; color:#cbd5e1; margin:0; line-height:1.4; }
.item { padding:18px; border-bottom:2px solid #334155; cursor:pointer; }
.item.active { background:#2563eb; }
.item h3 { font-size:18px; color:#fff; margin:0 0 6px 0; }
.item .date { font-size:13px; color:#94a3b8; }
.footer { background:#1e3a5f; padding:15px; text-align:center; font-size:14px; color:#cbd5e1; border-top:3px solid #2563eb; }
</style>
</head>
<body>

<div class="header">
<h1>@if(isset($settings['app_name'])){{ $settings['app_name'] }}@else School News @endif</h1>
</div>

<div class="container">
<div class="left">
@if(isset($news) && $news->count() > 0)
@php $num = 0; @endphp
@foreach($news as $item)
@if(isset($item->images) && $item->images->count() > 0)
@foreach($item->images as $img)
<div class="slide @if($num == 0) active @endif" data-id="{{ $item->id }}" data-time="{{ $img->slide_duration ?? 5000 }}">
<img src="{{ asset('storage/' . $img->url) }}" alt="">
<div class="info">
<h2>@if(isset($item->title)){{ $item->title }}@endif</h2>
<p>@if(isset($item->description)){{ strip_tags(html_entity_decode($item->description)) }}@endif</p>
</div>
</div>
@php $num++; @endphp
@endforeach
@else
<div class="slide @if($num == 0) active @endif" data-id="{{ $item->id }}" data-time="5000">
<div class="info" style="position:relative; top:30%; transform:translateY(-50%);">
<h2>@if(isset($item->title)){{ $item->title }}@endif</h2>
<p>@if(isset($item->description)){{ strip_tags(html_entity_decode($item->description)) }}@endif</p>
</div>
</div>
@php $num++; @endphp
@endif
@endforeach
@else
<div class="slide active"><div class="info" style="text-align:center; padding:50px;"><h2>No News Available</h2></div></div>
@endif
</div>

<div class="right">
@if(isset($news) && $news->count() > 0)
@php $i = 0; @endphp
@foreach($news as $item)
<div class="item @if($i == 0) active @endif" data-id="{{ $item->id }}">
<h3>@if(isset($item->title)){{ $item->title }}@endif</h3>
<div class="date">@if(isset($item->created_at)){{ $item->created_at->format('M d, Y') }}@endif</div>
</div>
@php $i++; @endphp
@endforeach
@endif
</div>
</div>

<div class="footer">
@if(isset($settings['footer_copyright_text'])){{ $settings['footer_copyright_text'] }}@else VCNS @ 2025 @endif
</div>

<script>
var slides = document.getElementsByClassName('slide');
var items = document.getElementsByClassName('item');
var idx = 0;

function next() {
    if (!slides || slides.length === 0) return;
    for (var i = 0; i < slides.length; i++) slides[i].className = 'slide';
    if (idx >= slides.length) idx = 0;
    slides[idx].className = 'slide active';
    var id = slides[idx].getAttribute('data-id');
    for (var j = 0; j < items.length; j++) {
        if (items[j].getAttribute('data-id') === id) {
            items[j].className = 'item active';
        } else {
            items[j].className = 'item';
        }
    }
    var t = parseInt(slides[idx].getAttribute('data-time')) || 5000;
    idx++;
    setTimeout(next, t);
}

if (slides.length > 0) next();
setTimeout(function() { location.reload(); }, 300000);
</script>

</body>
</html>
