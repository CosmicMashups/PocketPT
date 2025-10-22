'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "044b7e16e684904658df29ff13c1b04b",
"assets/AssetManifest.bin.json": "ba44bb3fc408270ce2a9ba652e5aab06",
"assets/AssetManifest.json": "5f811e044e6a99447b8bb11e87602282",
"assets/assets/data/exercises.csv": "49b6a1282e98de7634d977dcd5456dc1",
"assets/assets/data/ISO%2520Questionnaire.pdf": "613ffefb2d851ea4570fe71aca22b98c",
"assets/assets/data/treatment.csv": "da085b509d580b1ddaefad7e1273089d",
"assets/assets/images/bell.png": "c8d82b5f39765becb8432d939f2e8c51",
"assets/assets/images/check.png": "74a1b6d3297902956b2a9464c77c44fc",
"assets/assets/images/exercise/exercise.jpg": "9edce86f5e4d9dad487a8cb8aaabd280",
"assets/assets/images/exercise.png": "f778fa01bd7f9377c3f4658860235aa0",
"assets/assets/images/logo/bg.png": "ed2a2179025f1289b2672ac73f3106fe",
"assets/assets/images/logo/branding.png": "7b711f382a9b5453464a5af8d12dcc17",
"assets/assets/images/logo/google.png": "8742bd30e3f53973726cc44d8afb918e",
"assets/assets/images/logo/pocketpt.png": "5cfc93c2f981d0a28152ea2f567c8109",
"assets/assets/images/logo.png": "708097a641f5b48261b042a077e13aab",
"assets/assets/images/muscle/abdominals.png": "a69e181f10c89df18106b8fa77596744",
"assets/assets/images/muscle/ankle.png": "75f2447ab123593041c920286f1156c1",
"assets/assets/images/muscle/biceps.png": "b0510fd73900989fbc9a1aacb68e70a7",
"assets/assets/images/muscle/chest.png": "7d04c93cb4b76cc4b85c118c0fb5e975",
"assets/assets/images/muscle/deltoids.png": "5fbe434147f5e4ddd9b0bd59d58bcc52",
"assets/assets/images/muscle/diaphragm.png": "8a0b12996aa263ded5854b0b0b969b3d",
"assets/assets/images/muscle/forearm_muscles.png": "c08c65b2c0a4c538d631f81b48bdca70",
"assets/assets/images/muscle/glutes.png": "ad248de4f42cb162a22e96d687a0a02d",
"assets/assets/images/muscle/hamstrings.png": "4bd2c5ffc5842ffdb7a2bf735343bd36",
"assets/assets/images/muscle/hand_muscles.png": "b11a63825cea6e0077c55abf7b0fd3c8",
"assets/assets/images/muscle/lower_back.png": "64b4d26af2bec9200ddc57a9804dd2db",
"assets/assets/images/muscle/multifidus.png": "f31ee1bff8374e3d98796ee721ea77e7",
"assets/assets/images/muscle/neck_muscles.png": "96d637f2428976916b5f43bc33acc68a",
"assets/assets/images/muscle/obliques.png": "a0eb21155056c71c4201efb9366f16a9",
"assets/assets/images/muscle/quadriceps.png": "1c5b4548f44a624bed21c53a8bbe8537",
"assets/assets/images/muscle/rotator_cuff.png": "04313e888d0fa83928a0862f3b17fa9f",
"assets/assets/images/muscle/triceps.png": "3e39fefe1ca3d64de6169c7c7733ce1a",
"assets/assets/images/muscle/upper_back.png": "e0829fb1c63d15f3e1129c8c461042ad",
"assets/assets/images/muscle/wrist_flexors_extensors.png": "864dafea089e6af1f0a6e77f3f6ebbab",
"assets/assets/images/muscle_region/core_area.png": "5c75e61d8ac6e2ad6b06b805cedc84d4",
"assets/assets/images/muscle_region/joints.png": "8868d92d9202f3e737d190a9eaf5f5f0",
"assets/assets/images/muscle_region/lower_body.png": "a01c4a840364c1909946dca544a50f2c",
"assets/assets/images/muscle_region/neck.png": "b39ce425180bec54618e1bb94472a48b",
"assets/assets/images/muscle_region/upper_body.png": "e91b22113ab36cc7568380c89f48fb67",
"assets/assets/images/pfp/01.jpg": "73b9054c043dfbff8c552bbb6bbe51b8",
"assets/assets/images/pfp/02.jpg": "a5a3d49d77e82537f0f0f1cef28ce8b8",
"assets/assets/images/pfp/03.jpg": "b62924309e9e68f35534a552fd5d8fc0",
"assets/assets/images/pfp/04.jpg": "a8278beceff3ec118880b4d6f437e4e9",
"assets/assets/images/pfp/05.jpg": "6a07638046e48e47e3a573d79f807122",
"assets/assets/images/pfp/06.jpg": "88a1012c942362f42fed5f4a4a7b608a",
"assets/assets/images/pfp/07.jpg": "799750e956d9c7336be540a861bd1010",
"assets/assets/images/pfp/08.jpg": "26c3c884923deba72dd6c66915089de2",
"assets/assets/images/pfp/09.jpg": "3c1c631ed2a1e60fd20488c06c51f9f3",
"assets/assets/images/pfp/10.jpg": "b02c1a9c3f01d451148f2466aed965a1",
"assets/assets/images/pfp/11.jpg": "2e33b0abf66e462797117fa1e06720ce",
"assets/assets/images/pfp/12.jpg": "0dc225cded7be6028ba0aaac5aa41f7a",
"assets/assets/images/profile/about.png": "3a03213e66f7bd2e9611aad72cef815a",
"assets/assets/images/profile/coin.png": "880be7daa68fc51e2559f39023ffa715",
"assets/assets/images/profile/feedback.png": "79b03dc9be62e514e33d63fb94e3a268",
"assets/assets/images/profile/logout.png": "2a1bd8d0b54c875381e02d46bcd5dc9d",
"assets/assets/images/profile/profile.jpg": "cbc051318dc6793fb371e64ebc468524",
"assets/assets/images/profile/settings.png": "859824913cc0f9a488a622f5788c5558",
"assets/assets/images/streak.png": "a152df75c88a188c3872140db07ce1b9",
"assets/assets/images/time_spent.png": "cc842e39c18dd69ce03d301523df8303",
"assets/assets/images/title/ln_blue.png": "066e12c4bd7a16410b5f23f52bd8a513",
"assets/assets/images/title/ln_green.png": "cbc5fda67e54ca33e728ea9880af5f64",
"assets/assets/images/title/ln_purple.png": "868978d201b3d28dac6fb8702209fcb6",
"assets/assets/images/title/ln_yellow.png": "0bc1c4b2a60feeab7d6396cd5757bc92",
"assets/assets/images/welcome_1.jpg": "1046255ebb964405e0ed58c3e4714024",
"assets/assets/images/welcome_2.jpg": "e322250dee1634b11650ce9097f7d626",
"assets/assets/lottie/celebration.json": "92e885daa1d9a8fb2c910b1d47fd09ef",
"assets/assets/model/cnn_best.pt": "8b60e60510f09992e5e6a0e56c57685d",
"assets/assets/model/pain_labels.txt": "a8e8b966eb6129c0e2cbbfc76822b3c7",
"assets/assets/model/pain_recognition.pth": "7f41359a8302ac03f253a4cb2ce7d859",
"assets/assets/model/test_camera.py": "ed8db9dcc8223eccddf01090f10fcb7b",
"assets/assets/model/train_improved.py": "241b904b677185923008c70998b0c1f9",
"assets/assets/videos/arom_elbow.mp4": "0408ae835a1c3d09e084afc0ba3408a0",
"assets/FontManifest.json": "2bee15aaf1a69a97ef8e6b8ffa443a3f",
"assets/fonts/MaterialIcons-Regular.otf": "6acda306cfb5b3cbe6829a7d9a5ac5d7",
"assets/fonts/Poppins-Black.ttf": "14d00dab1f6802e787183ecab5cce85e",
"assets/fonts/Poppins-Bold.ttf": "08c20a487911694291bd8c5de41315ad",
"assets/fonts/Poppins-ExtraBold.ttf": "d45bdbc2d4a98c1ecb17821a1dbbd3a4",
"assets/fonts/Poppins-Italic.ttf": "c1034239929f4651cc17d09ed3a28c69",
"assets/fonts/Poppins-Light.ttf": "fcc40ae9a542d001971e53eaed948410",
"assets/fonts/Poppins-Regular.ttf": "093ee89be9ede30383f39a899c485a82",
"assets/fonts/PTSans-Bold.ttf": "7ce12caf9c41197f791da7e40970a69c",
"assets/fonts/PTSans-BoldItalic.ttf": "fcb302c740a71fd01f271b4db5f6f74d",
"assets/fonts/PTSans-Italic.ttf": "757eced08f7d7275568cd751b23e5207",
"assets/fonts/PTSans-Regular.ttf": "5b127e9e1cedad57860a5bb8b2cc9d61",
"assets/NOTICES": "bb566a2dfa0d92c07d1bcb2e22e3b285",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/packages/font_awesome_flutter/lib/fonts/fa-brands-400.ttf": "4769f3245a24c1fa9965f113ea85ec2a",
"assets/packages/font_awesome_flutter/lib/fonts/fa-regular-400.ttf": "3ca5dc7621921b901d513cc1ce23788c",
"assets/packages/font_awesome_flutter/lib/fonts/fa-solid-900.ttf": "a2eb084b706ab40c90610942d98886ec",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "86e461cf471c1640fd2b461ece4589df",
"canvaskit/canvaskit.js.symbols": "68eb703b9a609baef8ee0e413b442f33",
"canvaskit/canvaskit.wasm": "efeeba7dcc952dae57870d4df3111fad",
"canvaskit/chromium/canvaskit.js": "34beda9f39eb7d992d46125ca868dc61",
"canvaskit/chromium/canvaskit.js.symbols": "5a23598a2a8efd18ec3b60de5d28af8f",
"canvaskit/chromium/canvaskit.wasm": "64a386c87532ae52ae041d18a32a3635",
"canvaskit/skwasm.js": "f2ad9363618c5f62e813740099a80e63",
"canvaskit/skwasm.js.symbols": "80806576fa1056b43dd6d0b445b4b6f7",
"canvaskit/skwasm.wasm": "f0dfd99007f989368db17c9abeed5a49",
"canvaskit/skwasm_st.js": "d1326ceef381ad382ab492ba5d96f04d",
"canvaskit/skwasm_st.js.symbols": "c7e7aac7cd8b612defd62b43e3050bdd",
"canvaskit/skwasm_st.wasm": "56c3973560dfcbf28ce47cebe40f3206",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "76f08d47ff9f5715220992f993002504",
"flutter_bootstrap.js": "b0ed8c70776f4e344302d4f008745665",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "7c5ccdd371b525f3418ede5b4536b616",
"/": "7c5ccdd371b525f3418ede5b4536b616",
"main.dart.js": "65749e6bc43e86c3bacd40c6396f3b51",
"manifest.json": "299328e2a352fdf29d2bf1db9206fc89",
"splash/img/branding-1x.png": "685a9c2583b4e94f85580fcc7b145151",
"splash/img/branding-2x.png": "629804f93a80e12d748127943f16488f",
"splash/img/branding-3x.png": "67f9d60136b2b0f828784f1adea19bfc",
"splash/img/branding-4x.png": "2fd0e2c9838193fe4d68f7e2ac749a4f",
"splash/img/branding-dark-1x.png": "685a9c2583b4e94f85580fcc7b145151",
"splash/img/branding-dark-2x.png": "629804f93a80e12d748127943f16488f",
"splash/img/branding-dark-3x.png": "67f9d60136b2b0f828784f1adea19bfc",
"splash/img/branding-dark-4x.png": "2fd0e2c9838193fe4d68f7e2ac749a4f",
"splash/img/dark-1x.png": "76268aefd0a05f0ac2a74bfc1cb886eb",
"splash/img/dark-2x.png": "27ad591f29c826372549d81e20508d90",
"splash/img/dark-3x.png": "53d9a83c63f4fee390daecccb2a1b9d4",
"splash/img/dark-4x.png": "41883b62381b005bcac81980dea34f79",
"splash/img/light-1x.png": "76268aefd0a05f0ac2a74bfc1cb886eb",
"splash/img/light-2x.png": "27ad591f29c826372549d81e20508d90",
"splash/img/light-3x.png": "53d9a83c63f4fee390daecccb2a1b9d4",
"splash/img/light-4x.png": "41883b62381b005bcac81980dea34f79",
"splash/img/light-background.png": "ed2a2179025f1289b2672ac73f3106fe",
"version.json": "5532cbd9e8b9bc1f51fb2331c15f8f93"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
