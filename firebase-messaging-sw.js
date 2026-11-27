importScripts("https://www.gstatic.com/firebasejs/10.8.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.8.0/firebase-messaging-compat.js");

const firebaseConfig = {
  apiKey: "AIzaSyAfvdEg3adRoC_hUOr1j_NZjnWnx-b0xBI",
  authDomain: "mali-runanubandh.firebaseapp.com",
  projectId: "mali-runanubandh",
  storageBucket: "mali-runanubandh.firebasestorage.app",
  messagingSenderId: "1058215215310",
  appId: "1:1058215215310:web:95180272e96067cd94109f",
  measurementId: "G-ZBS6BV926F"
};

firebase.initializeApp(firebaseConfig);

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  const notificationTitle = payload.notification?.title || 'New Message';
  const notificationOptions = {
    body: payload.notification?.body,
    icon: '/icons/Icon-192.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
