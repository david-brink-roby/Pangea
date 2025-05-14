'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "3cc77d7106d590685f40cd4270d9abc2",
"assets/AssetManifest.bin.json": "2a473e21eb66502754e89e038d2ab6fd",
"assets/AssetManifest.json": "51747b906f9533746af44c6b7db29576",
"assets/assets/africa.png": "57d4f123ee114111177411f85260d292",
"assets/assets/africa_fossils.png": "3aff497b6071f5c55518f4693167d6d8",
"assets/assets/africa_glaciers.png": "f25b54fce85e5a697094c2f9899d84be",
"assets/assets/africa_rocks.png": "1ac15cc69a2596b74b0c8440d6fe8cb7",
"assets/assets/antartica.png": "b7648506433ca5b13b33d59c743e190c",
"assets/assets/antartica_fossils.png": "a75055d4fd28d1b056bb4839bf221a18",
"assets/assets/antartica_glaciers.png": "33684ccf51197bc6c327ecf62e4d3997",
"assets/assets/australia.png": "69387041648ac584d62864e8369f6593",
"assets/assets/australia_fossils.png": "b1273b4c25e10d61664f4513d307486d",
"assets/assets/australia_glaciers.png": "8905b16ae33918fb15093ce47751a7e9",
"assets/assets/eurasia.png": "ff6f7477d72d62aa1750482b2186c3b6",
"assets/assets/eurasia_fossils.png": "a9bc9b926cda17f5701bba8651af2965",
"assets/assets/eurasia_rocks.png": "f4bc2888908835b36f103921618b1207",
"assets/assets/fonts/NotoSans-Regular.ttf": "28ffc9e17c88630d93bf3fe92a687d04",
"assets/assets/greenland.png": "358e968b424daf0d693f7cd5a4483ac9",
"assets/assets/greenland_fossils.png": "9630bc8419d41db9b1343c3382bbf4e8",
"assets/assets/greenland_rocks.png": "a82cbb3bbd4b5b0079071984732c9c0f",
"assets/assets/india.png": "eaafa8b584f07ae80f22aabd79e1b213",
"assets/assets/india_fossils.png": "e05bf3ffbd7cb679ad95dd63f9375951",
"assets/assets/india_glaciers.png": "041401bd6ded95cc7d0bc36c3a753321",
"assets/assets/key_continent.png": "a21b1e9153db96bfc375c7fb32b0e7fe",
"assets/assets/key_fossils.png": "aede252891a0e7d7780278f34abdaf3d",
"assets/assets/key_glaciers.png": "fbfeb5962acf332c1805466a4f6468d6",
"assets/assets/key_rocks.png": "7c6f598f92b691e28772796598375e8a",
"assets/assets/madagascar.png": "d48fd2ae6341b6d7cf82357e6b7bd8b8",
"assets/assets/madagascar_fossils.png": "10229be6cbf2352c3472a53ba8fac629",
"assets/assets/madagascar_glaciers.png": "35746a9f31330742204a70dcd694c3d9",
"assets/assets/north_america.png": "e9cd4b438a75a6d5718479c2f2a15c7c",
"assets/assets/north_america_fossils.png": "9386f00c3f6dd4f7c00a864ac414ed82",
"assets/assets/north_america_rocks.png": "b4ad7fa5e1ccbe09e9d25990421bc538",
"assets/assets/rotate_hint.png": "25a1aaf38e88e522b6a89454303aafff",
"assets/assets/south_america.png": "115287a5103936543cb95129c80b35b3",
"assets/assets/south_america_fossils.png": "40c4c5dd82358053ff2286a375237dfe",
"assets/assets/south_america_glaciers.png": "1fb4785dd271a2208eb91ce2cc5047d9",
"assets/FontManifest.json": "1031a1db63b0247eb065faa27bfb7b0e",
"assets/fonts/MaterialIcons-Regular.otf": "e7069dfd19b331be16bed984668fe080",
"assets/NOTICES": "c1a6931851f30a94f50a4e1e5acae500",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "b93248a553f9e8bc17f1065929d5934b",
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
"flutter_bootstrap.js": "cd05a002fbfaa0b7e8a07f7a89184cf4",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "26a061fbe9eaf344cb785f722646c00d",
"/": "26a061fbe9eaf344cb785f722646c00d",
"main.dart.js": "a87cbfb78540946f5eef69e3a36985bb",
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
