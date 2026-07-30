importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyDBK5YWFLCAge9kVRcqru12ILSKsOP336U",
  authDomain: "rojgari-8f69b.firebaseapp.com",
  projectId: "rojgari-8f69b",
  storageBucket: "rojgari-8f69b.firebasestorage.app",
  messagingSenderId: "1056084039025",
  appId: "1:1056084039025:web:bf83c32f215964861cd2d0",
});

// Handles messages that arrive while no tab is focused (background/closed
// tab). Foreground messages are handled in Dart via FirebaseMessaging.onMessage.
firebase.messaging();
