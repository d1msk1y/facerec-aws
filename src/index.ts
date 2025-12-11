import type { S3Event, Context } from "aws-lambda";
import { S3Adapter } from "./infrastructure/S3Adapter.ts";
import { RekognitionAdapter } from "./infrastructure/RekognitionAdapter.ts";
import { RecognizeCelebrity } from "./application/RecognizeCelebrity.ts";

// --- Configuration ---
const REGION = process.env.AWS_REGION || "us-east-1";
// We can deduce the output bucket from the input bucket name (replace -in with -out)
// or use an environment variable. 
// Given the requirement "Init.sh sets up ...", let's assume a convention or Env Var.
// Using convention based on input bucket for simplicity, but Env Var is cleaner.
// REQUIRED: Environment Variable 'OUTPUT_BUCKET' should be set by Init.sh?
// Or just string manipulation: bucket-in -> bucket-out.

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

            // Determine Output Bucket
            // Logic: if srcBucket ends with "-in", replace with "-out". 
            // Else append "-out".
            const destBucket = srcBucket.endsWith("-in")
                ? srcBucket.slice(0, -3) + "-out"
                : `${srcBucket}-out`;

            await useCase.execute(srcBucket, srcKey, destBucket);
        }
    } catch (error) {
        console.error("Handler error:", error);
        // Fail execution to trigger retry? Or swallow?
        // Basic requirement: log error.
    }
};
