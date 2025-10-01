<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>{{ $settings['app_name'] ?? 'News' }}</title>
<style>
* { margin:0; padding:0; box-sizing:border-box; }
body { font-family:Arial,sans-serif; background:#0f172a; color:#fff; overflow:hidden; }
.header { background:linear-gradient(135deg,#1e293b 0%,#334155 100%); padding:25px; text-align:center; border-bottom:4px solid #3b82f6; box-shadow:0 4px 6px rgba(0,0,0,0.3); }
.header h1 { font-size:48px; color:#fff; margin:0; font-weight:bold; text-shadow:2px 2px 4px rgba(0,0,0,0.5); }
.main { display:table; width:100%; height:calc(100vh - 150px); }
.slider-section { display:table-cell; width:70%; background:#000; vertical-align:top; position:relative; }
.sidebar-section { display:table-cell; width:30%; background:#1e293b; vertical-align:top; border-left:3px solid #3b82f6; }
.slides { position:relative; width:100%; height:100%; }
.slide { display:none; position:absolute; top:0; left:0; width:100%; height:100%; }
.slide.active { display:block; }
.slide img { width:100%; height:70%; object-fit:contain; background:#000; }
.slide-text { position:absolute; bottom:0; left:0; right:0; background:rgba(15,23,42,0.95); padding:25px; border-top:3px solid #3b82f6; }
.slide-text h2 { font-size:36px; color:#fff; margin:0 0 15px 0; font-weight:bold; }
.slide-text p { font-size:22px; color:#cbd5e1; line-height:1.5; margin:0; }
.news-list { overflow-y:auto; height:100%; }
.news-item { padding:20px; border-bottom:2px solid #334155; cursor:pointer; transition:all 0.3s; }
.news-item:hover { background:#334155; }
.news-item.active { background:#3b82f6; border-left:5px solid #60a5fa; }
.news-item h3 { font-size:20px; color:#fff; margin:0 0 8px 0; font-weight:bold; line-height:1.3; }
.news-item .date { font-size:14px; color:#94a3b8; }
.footer { background:linear-gradient(135deg,#1e293b 0%,#334155 100%); padding:18px; text-align:center; font-size:16px; border-top:4px solid #3b82f6; color:#cbd5e1; }
.no-news { text-align:center; padding:100px 20px; font-size:32px; color:#64748b; }
</style>
</head>
<body>

<div class="header">
<h1><?php echo htmlspecialchars($settings['app_name'] ?? 'School News', ENT_QUOTES, 'UTF-8'); ?></h1>
</div>

<div class="main">
<div class="slider-section">
<div class="slides">
<?php if(isset($news) && count($news) > 0): ?>
    <?php $slideNum = 0; ?>
    <?php foreach($news as $item): ?>
        <?php if(isset($item->images) && count($item->images) > 0): ?>
            <?php foreach($item->images as $img): ?>
                <div class="slide <?php echo $slideNum == 0 ? 'active' : ''; ?>" data-time="<?php echo isset($img->slide_duration) ? $img->slide_duration : 5000; ?>" data-news-id="<?php echo $item->id; ?>">
                    <img src="<?php echo asset('storage/' . $img->url); ?>" alt="News">
                    <div class="slide-text">
                        <h2><?php echo htmlspecialchars($item->title, ENT_QUOTES, 'UTF-8'); ?></h2>
                        <p><?php echo htmlspecialchars(strip_tags($item->description), ENT_QUOTES, 'UTF-8'); ?></p>
                    </div>
                </div>
                <?php $slideNum++; ?>
            <?php endforeach; ?>
        <?php else: ?>
            <div class="slide <?php echo $slideNum == 0 ? 'active' : ''; ?>" data-time="5000" data-news-id="<?php echo $item->id; ?>">
                <div class="slide-text" style="position:relative; height:100%; display:table;">
                    <div style="display:table-cell; vertical-align:middle; text-align:center;">
                        <h2><?php echo htmlspecialchars($item->title, ENT_QUOTES, 'UTF-8'); ?></h2>
                        <p><?php echo htmlspecialchars(strip_tags($item->description), ENT_QUOTES, 'UTF-8'); ?></p>
                    </div>
                </div>
            </div>
            <?php $slideNum++; ?>
        <?php endif; ?>
    <?php endforeach; ?>
<?php else: ?>
    <div class="slide active"><div class="no-news">No news available</div></div>
<?php endif; ?>
</div>
</div>

<div class="sidebar-section">
<div class="news-list">
<?php if(isset($news) && count($news) > 0): ?>
    <?php $itemNum = 0; ?>
    <?php foreach($news as $item): ?>
        <div class="news-item <?php echo $itemNum == 0 ? 'active' : ''; ?>" data-item-id="<?php echo $item->id; ?>">
            <h3><?php echo htmlspecialchars($item->title, ENT_QUOTES, 'UTF-8'); ?></h3>
            <div class="date"><?php echo isset($item->created_at) ? date('M d, Y', strtotime($item->created_at)) : ''; ?></div>
        </div>
        <?php $itemNum++; ?>
    <?php endforeach; ?>
<?php endif; ?>
</div>
</div>
</div>

<div class="footer">
<?php echo htmlspecialchars($settings['footer_copyright_text'] ?? 'Copyright 2025', ENT_QUOTES, 'UTF-8'); ?>
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
