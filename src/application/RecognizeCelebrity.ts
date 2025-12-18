import type { IImageStorageService, IRecognitionService, RecognitionResult } from "../domain/types";

class RecognizeCelebrity {
    private storageService: IImageStorageService;
    private recognitionService: IRecognitionService;

    constructor(
        storageService: IImageStorageService,
        recognitionService: IRecognitionService
    ) {
        this.storageService = storageService;
        this.recognitionService = recognitionService;
    }

    async execute(sourceBucket: string, sourceKey: string, destBucket: string): Promise<void> {
        console.log(`[UseCase] Starting recognition. Source: ${sourceBucket}/${sourceKey}, Dest: ${destBucket}`);

        try {
            // 1. Retrieve Image
            const imageBytes = await this.storageService.retrieveImage(sourceBucket, sourceKey);

            // 2. Recognize Celebrity
            const result = await this.recognitionService.recognizeCelebrity(imageBytes);

            // 3. Prepare Result
            const finalResult: RecognitionResult = result || {
                Name: "No Match",
                MatchConfidence: 0
            };
            console.log(`[UseCase] Result: ${JSON.stringify(finalResult)}`);

            // 4. Save Result
            const destKey = sourceKey.replace(/\.[^/.]+$/, "") + ".json";
            await this.storageService.saveResult(destBucket, destKey, finalResult);

            console.log(`[UseCase] Saved result to ${destBucket}/${destKey}`);

        } catch (error) {
            console.error("[UseCase] Error executing use case:", error);
            throw error;
        }
    }
}

export default RecognizeCelebrity;