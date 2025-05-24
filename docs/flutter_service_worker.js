'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "de0e5c87a3bb2ece73687acae1cb10ea",
"assets/AssetManifest.bin.json": "45279d4fa4c61941e92aebffb2df92d7",
"assets/AssetManifest.json": "a5f88993b25ab605db0c480ae3ee57f4",
"assets/assets/acknowledgements.png": "ca2eba0f881393682ed5af9671fd8b4e",
"assets/assets/africa.png": "526a605970e0b1aa43ae0edd762e330d",
"assets/assets/africa_fossils.png": "f3a8a12aecfdf945e50e92b0eacb73b2",
"assets/assets/africa_glaciers.png": "d6cb31b76fba8b6031f0b08794774669",
"assets/assets/africa_rocks.png": "c3249f3d4030db7bd5bd0d47d19b3794",
"assets/assets/antartica.png": "f31e23288c905bf7a5469d47fc80a50b",
"assets/assets/antartica_fossils.png": "5ff81d47ab3ab0a3f332b468fca7db0b",
"assets/assets/antartica_glaciers.png": "78a6b8d70e28d103269bd8f888d0b371",
"assets/assets/australia.png": "627ca8c888a1bda14d70f2c277f5fc53",
"assets/assets/australia_fossils.png": "5219c93067a338d950fb2b23928c4a98",
"assets/assets/australia_glaciers.png": "017dec836ded34932fc361fcbb2bb93c",
"assets/assets/button_continents.png": "79ea1216d973192bf687ccfe568af55b",
"assets/assets/button_fossils.png": "6c5f5d8e65ff3908a81d1aa75586a5ba",
"assets/assets/button_glaciers.png": "7d5254be743fb5fb96f1c8b44a4d0904",
"assets/assets/button_rocks.png": "17ed0d748834767ff770cd511f64f900",
"assets/assets/eurasia.png": "848028533949e8c56b05f6e081f8d090",
"assets/assets/eurasia_fossils.png": "525e8e4b534d98acdae56e358ce3be2a",
"assets/assets/eurasia_rocks.png": "130f71af1487b392a231b1ffb9a7106a",
"assets/assets/fonts/NotoSans-Regular.ttf": "28ffc9e17c88630d93bf3fe92a687d04",
"assets/assets/greenland.png": "e1340617b57f7fb78323de480a6927d4",
"assets/assets/greenland_fossils.png": "611a2ac8f618bf02d272633d01bf87e4",
"assets/assets/greenland_rocks.png": "6ee649cdcbf12f22aa7db143184fd187",
"assets/assets/india.png": "9d37f7dde506986b38b5dc9f3d205c9d",
"assets/assets/india_fossils.png": "c8d0dc65d5ba599a2f6c8667d3b420e0",
"assets/assets/india_glaciers.png": "cfd8e140f3ad0db72082da9d73baa4e1",
"assets/assets/key_continents.png": "a21b1e9153db96bfc375c7fb32b0e7fe",
"assets/assets/key_fossils.png": "aede252891a0e7d7780278f34abdaf3d",
"assets/assets/key_glaciers.png": "fbfeb5962acf332c1805466a4f6468d6",
"assets/assets/key_rocks.png": "7c6f598f92b691e28772796598375e8a",
"assets/assets/madagascar.png": "c06681702af3b7b847a7e4b65f430dc0",
"assets/assets/madagascar_fossils.png": "3656204cf306b33b9b8b07a549020a84",
"assets/assets/madagascar_glaciers.png": "4583fb8b1f07cb03c628312613bab548",
"assets/assets/north_america.png": "ae8594a64f9af104cf8a92879f5cf9a3",
"assets/assets/north_america_fossils.png": "4e109f338c6f18000f95f52a99045737",
"assets/assets/north_america_rocks.png": "8d3b09ee40aed8832cdd0a712813063a",
"assets/assets/south_america.png": "76afc408d7cfd202a99b526617919f66",
"assets/assets/south_america_fossils.png": "6746dc916eeea8fe59651d0d9bfedaff",
"assets/assets/south_america_glaciers.png": "2afb4ed26418a0f33f40f8bc3ae46a66",
"assets/FontManifest.json": "1031a1db63b0247eb065faa27bfb7b0e",
"assets/fonts/MaterialIcons-Regular.otf": "e7069dfd19b331be16bed984668fe080",
"assets/NOTICES": "c1a6931851f30a94f50a4e1e5acae500",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "b93248a553f9e8bc17f1065929d5934b",
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
"flutter_bootstrap.js": "1cc68e4118d4b79c63578a3d7cad2df8",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "d1e690b982a174b6b0e70f9812aa9043",
"/": "d1e690b982a174b6b0e70f9812aa9043",
"main.dart.js": "558b73850142fe9ef00e1091b94bd96e",
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
