const { onDocumentCreated } =
  require("firebase-functions/v2/firestore");

const { initializeApp } =
  require("firebase-admin/app");

const { getMessaging } =
  require("firebase-admin/messaging");

initializeApp();

exports.notifyStudentsOfNewHackathon =
  onDocumentCreated("hackthons/{hackathonId}", async (event) => {
    if (!event.data) return;
    const hackathon = event.data.data();
    const hackathonId = event.params.hackathonId;

    const message = {
      topic: "students",
      notification: {
        title: "New Hackathon Available!",
        body: `${hackathon.title || "A new hackathon"} has been announced.`,
      },
      data: {
        type: "new_hackathon",
        hackathonId: hackathonId,
      },
    };

    await getMessaging().send(message);

    console.log("Hackathon notification sent:", hackathonId);
  });