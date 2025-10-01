// Import the Firebase scripts that are needed
importScripts("https://www.gstatic.com/firebasejs/9.23.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.23.0/firebase-messaging-compat.js");

// Initialize Firebase inside the service worker
firebase.initializeApp({
  apiKey: "AIzaSyD8-BI128vEK9a3q2Kemjv-ElrMFtIO2pE",
  appId: "1:660612640173:web:3ed89038bed33c9f104524",
  messagingSenderId: "660612640173",
  projectId: "promptia-332d0",
  authDomain: "promptia-332d0.firebaseapp.com",
  storageBucket: "promptia-332d0.firebasestorage.app",
  measurementId: "G-6SQ02BPCNT",
});

// Retrieve an instance of Firebase Messaging
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage(function (payload) {
  console.log("📩 Received background message: ", payload);

  const notificationTitle = payload.notification?.title || "New Notification";
  const notificationOptions = {
    body: payload.notification?.body || "You have a new message.",
    icon: "/icons/Icon-192.png", // adjust if needed
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
