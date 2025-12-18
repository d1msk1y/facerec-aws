import type { S3Event, Context } from "aws-lambda";
import S3Adapter from "./infrastructure/S3Adapter.js";
import RekognitionAdapter from "./infrastructure/RekognitionAdapter.js";
import RecognizeCelebrity from "./application/RecognizeCelebrity.js";


// --- Configuration ---
const REGION = process.env.AWS_REGION || "us-east-1";

// Composition Root
const s3Adapter = new S3Adapter(REGION);
const rekognitionAdapter = new RekognitionAdapter(REGION);
const useCase = new RecognizeCelebrity(s3Adapter, rekognitionAdapter);

export const handler = async (event: S3Event, context: Context): Promise<void> => {
    console.log("Event:", JSON.stringify(event, null, 2));

    try {
        for (const record of event.Records) {
            if (!record.s3) continue;

            const srcBucket = record.s3.bucket.name;
            const srcKey = decodeURIComponent(record.s3.object.key.replace(/\+/g, " "));

            const destBucket = srcBucket.endsWith("-in")
                ? srcBucket.slice(0, -3) + "-out"
                : `${srcBucket}-out`;

            await useCase.execute(srcBucket, srcKey, destBucket);
        }
    } catch (error) {
        console.error("Handler error:", error);
    }
};
