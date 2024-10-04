/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const { onRequest, onCall } = require("firebase-functions/v2/https");
const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const functions = require("firebase-functions");

// Initialize Firebase Admin SDK
admin.initializeApp();

// Retrieve Stripe secret key from environment config
const stripe = require('stripe')('sk_test_51PxbNPBNdgaaWhRghUfI4Ada0e6Wb3kZKZKfTzwKhssnJBebNa73QpXDwFOE3rfni9EvejuUE2q57IL7KA0mxWN600twh6B5Il');

// Function to create a Stripe PaymentIntent
exports.createPaymentIntent = onCall(async (request) => {
  const { amount, currency, jobId, buyerId, sellerId } = request.data;

  logger.info(`Creating PaymentIntent - Amount: ${amount}, Currency: ${currency}, JobID: ${jobId}, BuyerID: ${buyerId}, SellerID: ${sellerId}`);

  try {
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount,
      currency: currency,
      payment_method_types: ["card"],
      capture_method: "manual",
      metadata: {
        jobId: jobId,
        buyerId: buyerId,
        sellerId: sellerId
      }
    });

    logger.info(`PaymentIntent created successfully. ID: ${paymentIntent.id}`);
    return {
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id
    };
  } catch (error) {
    logger.error("Error creating PaymentIntent:", error);
    throw new functions.https.HttpsError("internal", "Unable to create PaymentIntent", error);
  }
});


// Function to capture a Stripe PaymentIntent
exports.capturePayment = onCall(async (request) => {
  const { paymentIntentId } = request.data;

  logger.info(`Capturing PaymentIntent - ID: ${paymentIntentId}`);

  try {
    const paymentIntent = await stripe.paymentIntents.capture(paymentIntentId);
    
    logger.info(`PaymentIntent captured successfully. ID: ${paymentIntentId}`);
    return { success: true, paymentIntent };
  } catch (error) {
    logger.error("Error capturing PaymentIntent:", error);
    throw new functions.https.HttpsError("internal", "Unable to capture PaymentIntent", error);
  }
});

// Firestore trigger to capture payment when job is marked as complete
exports.capturePaymentOnJobComplete = onDocumentUpdated("job_listings/{jobId}", async (event) => {
  const newValue = event.data.after.data();
  const previousValue = event.data.before.data();
  const jobId = event.params.jobId;
  const paymentIntentId = newValue.paymentIntentId;

  logger.info(`Job status changed for jobId: ${jobId}, from ${previousValue.status} to ${newValue.status}`);

  if (previousValue.status === "in_progress" && newValue.status === "complete") {
    try {
      // Ensure paymentIntentId is valid
      if (!paymentIntentId) {
        throw new Error('Missing paymentIntentId in Firestore document');
      }

      const paymentIntent = await stripe.paymentIntents.capture(paymentIntentId);
      
      logger.info(`Payment captured for jobId: ${jobId}, paymentIntentId: ${paymentIntentId}`);
      await admin.firestore().collection("job_listings").doc(jobId).update({
        paymentStatus: "captured"
      });

      return { success: true, paymentIntent };
    } catch (error) {
      logger.error(`Error capturing payment for jobId: ${jobId}`, error);
      return { success: false, error };
    }
  }

  return null;
});
