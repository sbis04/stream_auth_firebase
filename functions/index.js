const functions = require("firebase-functions");
const admin = require("firebase-admin");
const SecretManagerServiceClient = require("@google-cloud/secret-manager");
const StreamChat = require("stream-chat").StreamChat;
admin.initializeApp();

// async function accessSecretVersion(secretKeyName) {
//     const [secretVersion] = await secretClient.accessSecretVersion({
//         name: secretKeyName,
//     });
//     const secret = secretVersion.payload.data.toString();
//     return secret;
// }

exports.newUserSignUp = functions.auth.user().onCreate((user) => {
  const timestamp = admin.firestore.FieldValue.serverTimestamp();
  admin.firestore().collection("users").doc(user.uid).set({
    uid: user.uid,
    email: user.email,
    displayName: user.displayName,
    photoURL: user.photoURL,
    createdAt: timestamp,
  });

  console.log("New user created: ", user.uid);
});

exports.getStreamToken = functions.https.onCall((data, context) => {
  const userID = data.uid;
  const secretClient = new SecretManagerServiceClient();

  const [streamAPIKeyVersion] = secretClient.accessSecretVersion({
    name: "stream_api_key",
  });

  const [streamAPISecretVersion] = secretClient.accessSecretVersion({
    name: "stream_api_secret",
  });

  const streamAPIKey = streamAPIKeyVersion.payload.data.toString();
  const streamAPISecret = streamAPISecretVersion.payload.data.toString();

  // const streamAPIKey = await accessSecretVersion('stream_api_key');
  // const streamAPISecret = await accessSecretVersion('stream_api_secret');

  const streamClient = new StreamChat(streamAPIKey, streamAPISecret);
  const token = streamClient.createToken(userID);

  console.log("Stream token generated for user: ", userID);

  return token;
});

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//   functions.logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
