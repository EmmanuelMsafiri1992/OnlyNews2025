{{-- Vue.js Application Component - No HTML document structure, just the Vue app --}}

<style>
    /* TV-compatible styles for your original Vue.js app */
    * {
        margin: 0;
        padding: 0;
        box-sizing: border-box;
    }

    body {
        font-family: 'Inter', 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        line-height: 1.6;
        background-color: #f9fafb;
    }

    #app {
        width: 100%;
        min-height: 100vh;
    }

    .rtl {
        direction: rtl;
    }

    .animate-spin {
        animation: spin 1s linear infinite;
    }

    @keyframes spin {
        0% { transform: rotate(0deg); }
        100% { transform: rotate(360deg); }
    }

    /* TV-friendly button focus */
    button:focus, .focusable:focus {
        outline: 3px solid #3b82f6;
        outline-offset: 2px;
        box-shadow: 0 0 0 6px rgba(59, 130, 246, 0.3);
    }

    /* Large text for TV screens */
    @media screen and (min-width: 1920px) {
        .container { max-width: 1800px; }
        .text-xl { font-size: 2rem !important; }
        .text-2xl { font-size: 2.5rem !important; }
        .text-3xl { font-size: 3rem !important; }
        .text-base { font-size: 1.25rem !important; }
    }

    .line-clamp-2 {
        display: -webkit-box;
        -webkit-line-clamp: 2;
        -webkit-box-orient: vertical;
        overflow: hidden;
    }

    /* Custom scrollbar for news component */
    .custom-scrollbar::-webkit-scrollbar {
        width: 8px;
    }

    .custom-scrollbar::-webkit-scrollbar-track {
        background: #1e40af;
        border-radius: 4px;
    }

    .custom-scrollbar::-webkit-scrollbar-thumb {
        background: #3b82f6;
        border-radius: 4px;
    }

    .custom-scrollbar::-webkit-scrollbar-thumb:hover {
        background: #2563eb;
    }
</style>

{{-- Your original Vue.js application mount point --}}
<div id="app"></div>

<script>
    // Load your original translation data
    const translations = {
        en: {!! \Illuminate\Support\Facades\File::get(resource_path('lang/en.json')) !!},
        he: {!! \Illuminate\Support\Facades\File::get(resource_path('lang/he.json')) !!},
        ar: {!! \Illuminate\Support\Facades\File::get(resource_path('lang/ar.json')) !!}
    };

    // Your original Vue.js application exactly as designed
    const { createApp } = Vue;
    const { createI18n } = VueI18n;

    // TV-safe locale detection (from your original app.js)
    function getSafeLocale() {
        try {
            const urlLang = new URLSearchParams(window.location.search).get('lang');
            if (['en', 'he', 'ar'].includes(urlLang)) return urlLang;

            const browserLang = navigator.language.split('-')[0];
            return ['en', 'he', 'ar'].includes(browserLang) ? browserLang : 'en';
        } catch (error) {
            return 'en';
        }
    }

    const i18n = createI18n({
        locale: getSafeLocale(),
        fallbackLocale: 'en',
        messages: translations
    });

    // TV browser error handling (from your original app.js)
    function handleTVError(error, info) {
        console.error('Vue Error (TV Safe):', error, info);
        return true;
    }

    // Original Slider Component with all functionality
    const SliderComponent = {
        data() {
            return {
                newsItems: [],
                currentIndex: 0,
                isPlaying: true,
                slideInterval: null,
                slideTransition: 'transform 0.5s ease-in-out',
                imageLoaded: {},
                imageErrors: {},
                retryCount: 0,
                maxRetries: 3
            };
        },
        props: {
            items: {
                type: Array,
                default: () => []
            },
            displayTime: {
                type: Number,
                default: 5000
            }
        },
        watch: {
            items: {
                handler(newItems) {
                    this.newsItems = newItems;
                    this.resetSlider();
                },
                immediate: true
            }
        },
        methods: {
            resetSlider() {
                this.currentIndex = 0;
                this.imageLoaded = {};
                this.imageErrors = {};
                this.preloadImages();
                this.startAutoSlide();
            },
            preloadImages() {
                this.newsItems.forEach((item, index) => {
                    if (item.image_url) {
                        const img = new Image();
                        img.onload = () => this.handleImageLoad(index);
                        img.onerror = () => this.handleImageError(index);
                        img.src = item.image_url;
                    }
                });
            },
            handleImageLoad(index) {
                this.$set(this.imageLoaded, index, true);
                this.$set(this.imageErrors, index, false);
            },
            handleImageError(index) {
                this.$set(this.imageErrors, index, true);
                this.$set(this.imageLoaded, index, false);
            },
            goToSlide(index) {
                this.currentIndex = index;
                this.handleSlideChange(index);
            },
            nextSlide() {
                this.currentIndex = (this.currentIndex + 1) % this.newsItems.length;
                this.handleSlideChange(this.currentIndex);
            },
            prevSlide() {
                this.currentIndex = this.currentIndex === 0 ? this.newsItems.length - 1 : this.currentIndex - 1;
                this.handleSlideChange(this.currentIndex);
            },
            handleSlideChange(index) {
                this.stopAutoSlide();
                this.$emit('slide-change', { index, item: this.newsItems[index] });
                this.startAutoSlide();
            },
            startAutoSlide() {
                this.stopAutoSlide();
                if (this.newsItems.length > 1 && this.isPlaying) {
                    this.slideInterval = setTimeout(() => {
                        this.nextSlide();
                    }, this.displayTime);
                }
            },
            stopAutoSlide() {
                if (this.slideInterval) {
                    clearTimeout(this.slideInterval);
                    this.slideInterval = null;
                }
            },
            pause() {
                this.isPlaying = false;
                this.stopAutoSlide();
            },
            resume() {
                this.isPlaying = true;
                this.startAutoSlide();
            }
        },
        mounted() {
            this.startAutoSlide();
        },
        beforeUnmount() {
            this.stopAutoSlide();
        },
        template: `
            <div class="relative h-full w-full overflow-hidden rounded-xl bg-gray-900"
                 @@mouseenter="$emit('pause')"
                 @@mouseleave="$emit('resume')"
                 tabindex="0"
                 @@keydown.left="prevSlide"
                 @@keydown.right="nextSlide"
                 aria-label="News Slider">

               <div v-if="!newsItems || newsItems.length === 0" class="absolute inset-0 flex flex-col items-center justify-center bg-gray-200 text-gray-600 p-4">
                   <div class="animate-spin rounded-full h-16 w-16 sm:h-20 sm:w-20 border-b-4 border-blue-600 mx-auto"></div>
                   <p class="mt-6 text-lg sm:text-xl font-medium">Loading images...</p>
               </div>

               <div v-else class="slider-container h-full w-full flex" :style="{ transform: \`translateX(-\${currentIndex * 100}%)\` }">
                   <div v-for="(item, index) in newsItems" :key="item.id || \`slide-\${index}\`"
                        class="slider-slide h-full flex-none w-full relative">
                       <img :src="item.image_url"
                            :alt="item.title || 'News image'"
                            :class="['news-image w-full h-full object-cover transition-opacity duration-300', {
                                loading: !imageLoaded[index] && !imageErrors[index],
                                'opacity-0': imageErrors[index]
                            }]"
                            @@load="handleImageLoad(index)"
                            @@error="handleImageError(index)"
                            loading="lazy">

                       <div v-if="imageErrors[index]" class="absolute inset-0 flex items-center justify-center bg-gradient-to-br from-blue-600 to-purple-700 text-white p-6 sm:p-8 lg:p-12 text-center">
                           <div class="max-w-md">
                               <svg class="w-20 h-20 sm:w-24 sm:h-24 mx-auto mb-6 opacity-80" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                   <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10a2 2 0 012 2v1m2 13a2 2 0 01-2-2V7m2 13a2 2 0 002-2V9a2 2 0 00-2-2h-2m-4-3H9M7 16h6M7 8h6v4H7V8z" />
                               </svg>
                               <h3 class="text-xl sm:text-2xl lg:text-3xl font-bold mb-3" v-html="item.title || 'News Update'"></h3>
                               <p class="text-base sm:text-lg opacity-90">@{{ item.category || 'Latest News' }}</p>
                           </div>
                       </div>

                       <div class="absolute inset-0 bg-gradient-to-t from-black/70 via-transparent to-transparent flex items-end p-6 sm:p-8 lg:p-10">
                           <div class="text-white w-full">
                               <h3 class="text-xl sm:text-2xl lg:text-3xl font-bold mb-2 line-clamp-2" v-html="item.title || 'Untitled'"></h3>
                               <p class="text-sm sm:text-base opacity-90 line-clamp-1">@{{ item.date || '' }}</p>
                           </div>
                       </div>
                   </div>
               </div>

               <!-- Navigation dots -->
               <div v-if="newsItems && newsItems.length > 1" class="absolute bottom-4 sm:bottom-6 left-1/2 transform -translate-x-1/2 flex space-x-2 sm:space-x-3 z-10">
                   <button v-for="(item, index) in newsItems" :key="\`dot-\${index}\`"
                           @@click="goToSlide(index)"
                           :class="['w-3 h-3 sm:w-4 sm:h-4 rounded-full transition-all duration-300 focus:outline-none focus:ring-2 focus:ring-blue-400 focus:ring-offset-2 focus:ring-offset-gray-800',
                                   currentIndex === index ? 'bg-white' : 'bg-white bg-opacity-50 hover:bg-opacity-75']"
                           :aria-label="\`Go to slide \${index + 1}\`">
                   </button>
               </div>

               <!-- Previous button -->
               <button v-if="newsItems && newsItems.length > 1"
                       @@click="prevSlide"
                       class="absolute left-4 sm:left-6 top-1/2 transform -translate-y-1/2 bg-black bg-opacity-50 text-white p-3 sm:p-4 rounded-full hover:bg-opacity-75 transition-all duration-300 focus:outline-none focus:ring-2 focus:ring-blue-400 focus:ring-offset-2 focus:ring-offset-gray-800 z-10"
                       aria-label="Previous slide">
                   <svg class="w-6 h-6 sm:w-8 sm:h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                       <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
                   </svg>
               </button>

               <!-- Next button -->
               <button v-if="newsItems && newsItems.length > 1"
                       @@click="nextSlide"
                       class="absolute right-4 sm:right-6 top-1/2 transform -translate-y-1/2 bg-black bg-opacity-50 text-white p-3 sm:p-4 rounded-full hover:bg-opacity-75 transition-all duration-300 focus:outline-none focus:ring-2 focus:ring-blue-400 focus:ring-offset-2 focus:ring-offset-gray-800 z-10"
                       aria-label="Next slide">
                   <svg class="w-6 h-6 sm:w-8 sm:h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                       <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                   </svg>
               </button>
           </div>
        `
    };

    // Original News Detail Component
    const NewsDetailComponent = {
        props: {
            currentNews: {
                type: Object,
                default: () => null
            }
        },
        template: `
            <div class="h-full bg-blue-700 text-white flex flex-col rounded-xl">
                <div class="p-4 sm:p-6 lg:p-8 border-b border-blue-600">
                    <h2 class="text-xl sm:text-2xl lg:text-3xl font-bold break-words leading-tight" v-html="currentNews.title || 'No Title'"></h2>
                </div>

                <div class="p-4 sm:p-6 lg:p-8 flex-1 bg-blue-800 flex flex-col">
                    <div v-if="currentNews" class="flex-1 flex flex-col">
                        <div class="flex flex-wrap items-center gap-2 lg:gap-4 mb-4 lg:mb-6">
                            <div class="flex items-center text-sm lg:text-base text-blue-200">
                                <svg class="w-4 h-4 lg:w-5 lg:h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                                </svg>
                                @{{ currentNews.date || 'No Date' }}
                            </div>
                            <div v-if="currentNews.category" class="px-3 py-1 lg:px-4 lg:py-2 bg-blue-600 text-blue-100 text-sm lg:text-base rounded-full font-medium mb-2 sm:mb-0">
                                @{{ currentNews.category }}
                            </div>
                        </div>

                        <div class="flex-1 flex flex-col overflow-y-auto custom-scrollbar pr-2">
                            <p class="text-blue-100 text-sm sm:text-base lg:text-lg leading-relaxed break-words flex-1" v-html="currentNews.full_description || currentNews.description || 'No Description'"></p>
                        </div>

                        <div v-if="currentNews.location || currentNews.time || currentNews.organizer" class="bg-blue-700 rounded-lg p-4 lg:p-6 mt-4 lg:mt-6">
                            <h4 class="font-semibold text-white mb-3 lg:mb-4 text-base lg:text-lg">Event Details</h4>
                            <div class="space-y-2 lg:space-y-3">
                                <div v-if="currentNews.location" class="flex items-center text-sm lg:text-base text-blue-200">
                                    <svg class="w-4 h-4 lg:w-5 lg:h-5 mr-2 lg:mr-3 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                                    </svg>
                                    <span><strong>Location:</strong> @{{ currentNews.location }}</span>
                                </div>

                                <div v-if="currentNews.time" class="flex items-center text-sm lg:text-base text-blue-200">
                                    <svg class="w-4 h-4 lg:w-5 lg:h-5 mr-2 lg:mr-3 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                                    </svg>
                                    <span><strong>Time:</strong> @{{ currentNews.time }}</span>
                                </div>

                                <div v-if="currentNews.organizer" class="flex items-center text-sm lg:text-base text-blue-200">
                                    <svg class="w-4 h-4 lg:w-5 lg:h-5 mr-2 lg:mr-3 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                                    </svg>
                                    <span><strong>Organizer:</strong> @{{ currentNews.organizer }}</span>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div v-else class="flex-1 flex items-center justify-center text-center text-blue-200 text-lg sm:text-xl lg:text-2xl">
                        No News Articles Yet
                    </div>
                </div>
            </div>
        `
    };

    // Original Header Component
    const HeaderComponent = {
        data() {
            return {
                headerTitle: 'WeARE News'
            };
        },
        async mounted() {
            await this.fetchHeaderTitle();
        },
        methods: {
            async fetchHeaderTitle() {
                try {
                    const response = await fetch('/api/settings');
                    if (response.ok) {
                        const settings = await response.json();
                        if (settings && settings.app_name) {
                            this.headerTitle = settings.app_name;
                        }
                    }
                } catch (error) {
                    console.error('Error fetching header title:', error);
                }
            }
        },
        template: `
            <header class="bg-white shadow-sm border-b border-gray-200">
                <div class="container mx-auto px-4 py-6">
                    <h1 class="text-3xl font-bold text-gray-900">@{{ headerTitle }}</h1>
                    <p class="text-gray-600 mt-2">Stay updated with our upcoming news</p>
                </div>
            </header>
        `
    };

    // Original Footer Component
    const FooterComponent = {
        data() {
            return {
                copyrightText: '© 2024 WeARE News. All rights reserved.',
                contactInfo: 'Visit our website for more information.'
            };
        },
        async mounted() {
            await this.fetchFooterSettings();
        },
        methods: {
            async fetchFooterSettings() {
                try {
                    const response = await fetch('/api/settings');
                    if (response.ok) {
                        const settings = await response.json();
                        if (settings) {
                            if (settings.footer_copyright) {
                                this.copyrightText = settings.footer_copyright;
                            }
                            if (settings.footer_contact) {
                                this.contactInfo = settings.footer_contact;
                            }
                        }
                    }
                } catch (error) {
                    console.error('Error fetching footer settings:', error);
                }
            }
        },
        template: `
            <footer class="bg-white border-t border-gray-200">
                <div class="container mx-auto px-4 py-6 text-center text-gray-600">
                    <p>@{{ copyrightText }}</p>
                    <p class="text-sm mt-2">@{{ contactInfo }}</p>
                </div>
            </footer>
        `
    };

    // Main Vue App with all original functionality
    const App = {
        components: {
            SliderComponent,
            NewsDetailComponent,
            HeaderComponent,
            FooterComponent
        },
        data() {
            return {
                newsItems: [],
                processedNewsItems: [],
                currentNews: null,
                loading: true,
                error: null,
                retryCount: 0,
                maxRetries: 3,
                refreshInterval: null,
                slideDisplayTime: 5000,
                slideNewsCount: 5,
                settings: {}
            };
        },
        computed: {
            processedNewsItems() {
                return this.newsItems.map((item, index) => {
                    const processedImages = [];

                    if (item.image_url) {
                        processedImages.push(item.image_url);
                    }

                    if (item.images && Array.isArray(item.images)) {
                        item.images.forEach(img => {
                            const imgUrl = typeof img === 'string' ? img : (img.image_path || img.url || img.image_url);
                            if (imgUrl && !processedImages.includes(imgUrl)) {
                                processedImages.push(imgUrl);
                            }
                        });
                    }

                    const primaryImage = processedImages.length > 0 ? processedImages[0] : null;
                    return {
                        id: item.id || `news-${index}`,
                        title: item.title || item.headline || 'No Title',
                        description: item.description || item.summary || item.content || 'No description available',
                        full_description: item.full_description || item.description || item.summary || item.content || 'No description available',
                        date: item.date || item.published_at || item.created_at || new Date().toLocaleDateString(),
                        category: item.category || item.type || 'News',
                        location: item.location || '',
                        time: item.time || item.event_time || '',
                        organizer: item.organizer || item.author || '',
                        image_url: primaryImage,
                        images: processedImages
                    };
                });
            },
            noNewsMessage() {
                if (this.error) {
                    return 'Error loading news';
                }
                return 'No news available';
            }
        },
        methods: {
            handleSlideChange(data) {
                this.currentNews = data.item;
            },
            startAutoSlide() {
                if (this.$refs.slider && this.$refs.slider.startAutoSlide) {
                    this.$refs.slider.startAutoSlide();
                }
            },
            stopAutoSlide() {
                if (this.$refs.slider && this.$refs.slider.stopAutoSlide) {
                    this.$refs.slider.stopAutoSlide();
                }
            },
            getApiBaseUrl() {
                if (typeof window !== 'undefined' && window.location) {
                    return `${window.location.protocol}//${window.location.host}`;
                }
                return 'http://127.0.0.1:8000';
            },
            async fetchSettings() {
                try {
                    const apiBaseUrl = this.getApiBaseUrl();
                    const response = await fetch(apiBaseUrl + '/api/settings', {
                        method: 'GET',
                        headers: {
                            'Accept': 'application/json',
                            'Content-Type': 'application/json'
                        },
                        timeout: 10000
                    });
                    if (response.ok) {
                        const settings = await response.json();
                        this.settings = settings;
                        if (settings.slider_display_time) {
                            this.slideDisplayTime = parseInt(settings.slider_display_time, 10) * 1000;
                        }
                        if (settings.slider_news_count) {
                            this.slideNewsCount = parseInt(settings.slider_news_count, 10);
                        }
                        return settings;
                    }
                } catch (error) {
                    console.error('Could not fetch settings:', error);
                }
                return {};
            },
            async initializeApp() {
                console.log('WeARE News App - Original System Starting...');
                try {
                    await this.fetchSettings();
                    await this.fetchNews();
                    this.startAutoSlide();
                    this.refreshInterval = setInterval(() => {
                        this.fetchNews();
                    }, 5 * 60 * 1000);
                    if (window.TVRemoteHelper) {
                        setTimeout(() => {
                            window.TVRemoteHelper.init();
                        }, 1000);
                    }
                    console.log('WeARE News App - Successfully Initialized!');
                } catch (error) {
                    console.error('Error initializing app:', error);
                    this.error = error.message;
                }
            },
            async fetchNews() {
                try {
                    this.loading = true;
                    this.error = null;
                    const apiUrl = this.getApiBaseUrl() + '/api/news';
                    console.log('Fetching news from:', apiUrl);
                    const response = await fetch(apiUrl, {
                        headers: {
                            'Accept': 'application/json',
                            'Content-Type': 'application/json'
                        },
                        timeout: 15000
                    });

                    if (response.ok) {
                        const data = await response.json();
                        console.log('News data received:', data);

                        if (data.success && Array.isArray(data.data)) {
                            this.newsItems = data.data.slice(0, this.slideNewsCount);
                            this.retryCount = 0;

                            if (this.newsItems.length > 0) {
                                this.currentNews = this.processedNewsItems[0];
                            }
                        } else {
                            console.warn('Unexpected news data format:', data);
                        }
                    } else {
                        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
                    }
                } catch (error) {
                    console.error('Error fetching news:', error);
                    this.error = error.message;
                    this.retryCount++;
                    if (this.retryCount < this.maxRetries) {
                        console.log(`Retrying... (${this.retryCount}/${this.maxRetries})`);
                        setTimeout(() => this.fetchNews(), 2000 * this.retryCount);
                    }
                } finally {
                    this.loading = false;
                }
            }
        },
        template: `
            <div id="app" class="min-h-screen flex flex-col" :class="{ 'rtl': $i18n.locale === 'he' || $i18n.locale === 'ar' }">
                <!-- Header Component -->
                <header-component />

                <!-- Main Content Area -->
                <main class="flex-1 bg-gray-50 p-4 sm:p-6 lg:p-8 xl:p-12">
                    <div class="container mx-auto h-full">
                        <div v-if="loading" class="text-center flex flex-col items-center justify-center h-full min-h-[50vh]">
                            <div class="inline-block animate-spin rounded-full h-32 w-32 border-b-4 border-gray-900"></div>
                            <p class="text-gray-500 mt-8 text-xl sm:text-2xl">Loading...</p>
                        </div>
                        <div v-else-if="processedNewsItems.length > 0" class="grid grid-cols-1 lg:grid-cols-2 gap-8 lg:gap-12 h-full">
                            <!-- Left Column: Enhanced News Slider -->
                            <div class="h-full min-h-[400px] lg:min-h-[600px]">
                                <slider-component
                                    ref="slider"
                                    :items="processedNewsItems"
                                    :display-time="slideDisplayTime"
                                    @@slide-change="handleSlideChange">
                                </slider-component>
                            </div>

                            <!-- Right Column: Enhanced News Details -->
                            <div class="h-full min-h-[400px] lg:min-h-[600px]">
                                <news-detail-component :current-news="currentNews"></news-detail-component>
                            </div>
                        </div>
                        <div v-else class="text-center flex flex-col items-center justify-center h-full min-h-[50vh]">
                            <div class="max-w-md mx-auto">
                                <div class="text-gray-500 text-2xl sm:text-3xl lg:text-4xl">
                                    <svg class="mx-auto h-20 w-20 sm:h-24 sm:w-24 text-gray-400 mb-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10a2 2 0 012 2v1m2 13a2 2 0 01-2-2V7m2 13a2 2 0 002-2V9a2 2 0 00-2-2h-2m-4-3H9M7 16h6M7 8h6v4H7V8z" />
                                    </svg>
                                    <p class="mt-4">@{{ noNewsMessage }}</p>
                                </div>
                            </div>
                        </div>
                    </div>
                </main>

                <!-- Footer Component -->
                <footer-component />
            </div>
        `,
        async mounted() {
            await this.initializeApp();
        },
        beforeUnmount() {
            if (this.refreshInterval) {
                clearInterval(this.refreshInterval);
            }
        }
    };

    // Initialize your original Vue.js application
    const app = createApp(App);
    app.use(i18n);
    app.mount('#app');
</script>