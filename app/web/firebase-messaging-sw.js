// This file allows Firebase Cloud Messaging to run in the background on Web PWAs
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyBs3e8m1l2CpdzQvmgZcXVAwB454KjlQlg",
  authDomain: "rupayan-81953.firebaseapp.com",
  projectId: "rupayan-81953",
  storageBucket: "rupayan-81953.firebasestorage.app",
  messagingSenderId: "648404388408",
  appId: "1:648404388408:web:dc86d54ad332e9e4d634cd"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);

  if (payload.notification) {
    const notificationTitle = payload.notification.title;
    const notificationOptions = {
      body: payload.notification.body,
      icon: '/favicon.png',
      data: payload.data
    };

    self.registration.showNotification(notificationTitle, notificationOptions);
  }
});

self.addEventListener('notificationclick', function(event) {
  event.notification.close();

  // Handle deep link route 
  const route = event.notification.data?.route || '/projects';
  event.waitUntil(
    clients.openWindow('/#' + route) 
  );
});
