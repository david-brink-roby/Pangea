'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "9d039d36c560cef59ba16156f8465642",
"assets/AssetManifest.bin.json": "dec08ae3788035f91ce9309e362d593b",
"assets/AssetManifest.json": "ce1376d7db6746d076ae5067170aedf7",
"assets/assets/africa.png": "deaa92f304ad2adafac8a7b7d40c1eea",
"assets/assets/africa_fossils.png": "baab2b80451d9f78ed2ce4a307c38054",
"assets/assets/africa_glaciers.png": "f8839c9e8582fcead6ab8b13bfc2bafb",
"assets/assets/africa_rocks.png": "21ee5c2f86fba0760a1fba58ebdd69bc",
"assets/assets/antartica.png": "1180549136dc8e4a07857c0f1dcfb298",
"assets/assets/antartica_fossils.png": "f5f2533c3b9a14a69c625d1166dcf10c",
"assets/assets/antartica_glaciers.png": "6effaafd9a384725c4a46300560d7985",
"assets/assets/arabia.png": "068ed74bd903f0128631c897804d7825",
"assets/assets/australia.png": "3b461a0d87543c2cee64b92225f50b47",
"assets/assets/australia_fossils.png": "7bd2455e872ec3d5bf5c1bea80f29046",
"assets/assets/australia_glaciers.png": "9d4040e00a19d54359d9ad5767269964",
"assets/assets/eurasia.png": "c70a4f3d3e18b37813255c490329e9a0",
"assets/assets/eurasia_rocks.png": "e3efd3ec270de7bbcd302110dcf0113f",
"assets/assets/fonts/NotoSans-Regular.ttf": "28ffc9e17c88630d93bf3fe92a687d04",
"assets/assets/greenland.png": "5e12a5ed98fe23275d9670a774e0d1d7",
"assets/assets/india.png": "a8f1c6411449205cbd9e27ba9cc63a8b",
"assets/assets/india_fossils.png": "50d0f6ea1c77b8e93ab54f716389fbc0",
"assets/assets/india_glaciers.png": "ece20f67f08aaf00033a84e54be71699",
"assets/assets/madagascar.png": "028b7d77d2f4598c5e8c5dc29c20737c",
"assets/assets/madagascar_fossils.png": "08a5275132848b94bdec30fd9c3dbe79",
"assets/assets/madagascar_glaciers.png": "4590d36208b2471c74bb0c6e7734e176",
"assets/assets/north_america.png": "fa88be663c0a028575047a03c921c2d9",
"assets/assets/north_america_rocks.png": "5ae1459db6a9dd0a12588ee667505687",
"assets/assets/south_america.png": "2722af3a38f22e47b13fcb3334853c30",
"assets/assets/south_america_fossils.png": "e7cfa106cd4e17735a95813a5c47462a",
"assets/assets/south_america_glaciers.png": "da98d3ec6bda564e2c5d4ae3f7ff8ad9",
"assets/assets/south_america_rocks.png": "74a9a28b59f8711e2b41b769898d2d03",
"assets/FontManifest.json": "451b916173f2bc9f417bbafd8bf5408c",
"assets/fonts/MaterialIcons-Regular.otf": "e7069dfd19b331be16bed984668fe080",
"assets/NOTICES": "8c997229e13f4879c73ee476e34f61fb",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "6cfe36b4647fbfa15683e09e7dd366bc",
"canvaskit/canvaskit.js.symbols": "68eb703b9a609baef8ee0e413b442f33",
"canvaskit/canvaskit.wasm": "efeeba7dcc952dae57870d4df3111fad",
"canvaskit/chromium/canvaskit.js": "ba4a8ae1a65ff3ad81c6818fd47e348b",
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
"flutter_bootstrap.js": "30b979b4d7e7cdcb9f58f55b01cb8c2a",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "b885b1769ed8cb5075aa3dd41087fc0d",
"/": "b885b1769ed8cb5075aa3dd41087fc0d",
"main.dart.js": "5331fec16ef8139a6b757f74cb924048",
"manifest.json": "86b6c8ee9e53441604080fc344a53eb7",
"version.json": "88c37cb86d6ac92816be1bb8c1272fac"};
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
