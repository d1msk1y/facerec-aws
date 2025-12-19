# Cloud-Native Face Recognition Service

This repository contains the implementation for the **Cloud Service for recognizing known personalities on photos**, fulfilling the requirements for the **Abschlussarbeit Modul 346: Cloud Solutions Concept and Realization** .

The project employs a fully automated, event-driven, **Cloud Native** architecture, leveraging **Serverless Computing** and **Infrastructure as Code (IaC)** principles.

---

## 1. Project Goals and Requirements

The primary objective is to design and implement a highly automated cloud service capable of performing celebrity recognition .

### Core Functional Goals 
1.  **Face Recognition Service:** Create a service using an AWS Lambda function that recognizes known personalities in photos.
2.  **Trigger Mechanism:** The recognition process must be started automatically via a **trigger** when a photo file is uploaded to an input location (In-Bucket).
3.  **Result Output:** The details of the analysis, including the recognized `Name` and **MatchConfidence** (Trefferwahrscheinlichkeit), must be saved as a **JSON file** in an output location (Out-Bucket) .

### Deployment and DevOps Goals
1.  **Deployment Environment:** The service, including all necessary components, must be put into operation within the **AWS Learner-Lab** .
2.  **Full Automation (IaC):** The service must be installed **fully automatically** (vollautomatisiert) by executing a **single script** (e.g., `Init.sh`) from a client (Windows or Linux) . This adheres to the principle of Infrastructure as Code .
3.  **Testing:** A separate **Test-Script** is required to automate the testing process, including uploading the photo, waiting for completion, downloading the JSON result, and outputting the recognized names and probabilities .
4.  **Version Control:** All required files and the documentation must be managed and **versioned** in a **Git-Repository** .
5.  **Documentation:** The documentation must be written in **Markdown** format, with this `Readme.md` serving as the mandatory **entry point** .

---

## 2. Technical Stack and Architecture

The entire architecture is designed around the **AWS Public Cloud**  and adheres to the **Cloud Native** maturity phase, focusing on scalability and efficiency .

### 2.1 Cloud Services (Workloads)

The service utilizes the following essential AWS services (Cloud-Workloads) :

| Category                    | AWS Service                   | NIST Model                         | Role in Project                                                                                                               |
| :-------------------------- | :---------------------------- | :--------------------------------- | :---------------------------------------------------------------------------------------------------------------------------- |
| **Cloud Provider**          | **Amazon Web Services (AWS)** | Public Cloud                       | The infrastructure provider, founded in 2006 .                                                                                |
| **Compute & Logic**         | **AWS Lambda**                | PaaS (Platform as a Service)       | Hosts the core business logic as a **Serverless Function** .                                                                  |
| **Artificial Intelligence** | **AWS Rekognition**           | Machine Learning Workload          | Performs the celebrity recognition (Recognizing celebrities) .                                                                |
| **Storage (Input/Output)**  | **Amazon S3**                 | Object Storage                     | Provides the S3 Buckets (In- and Out-Bucket) necessary for triggering the function and storing the final JSON analysis file . |
| **Identity Management**     | **AWS IAM**                   | Security, Identity, and Compliance | Used to set the **correct permissions** (Berechtigungen) for the Lambda function to access S3 and Rekognition .               |

### 2.2 Development and Automation Tools

The implementation focuses on automating all aspects of deployment and configuration management.

| Tool / Technology          | Category              | Role in Project                                                                                                                                                        |
| :------------------------- | :-------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Programming Language**   | Function Logic        | **TypeScript** (compiling to JavaScript/Node.js for Lambda runtime).                                                                                                   |
| **Infrastructure as Code** | Automation Method     | Implementation relies on **Imperative IaC** .                                                                                                                          |
| **IaC Tool**               | CLI Management        | **AWS CLI** (Command Line Interface). Used to control **all AWS services** through commands and automate deployment via scripts .                                      |
| **Deployment Scripts**     | Automation            | Shell scripts (`Init.sh`, `Test-Script`) ensure all components are installed and tested **fully automatically** .                                                      |
| **Version Control**        | DevOps Practice       | **Git**. Ensures traceability (who, when, what) of all code and documentation via regular commits .                                                                    |
| **Client Environment**     | Operating System Tool | **Windows Subsystem for Linux (WSL)** and **Windows**. **WSL** however, enables execution of Linux programs and shell scripts directly on the Windows client machine . |
| **Documentation**          | Required Format       | **Markdown**. Used for all project documentation, including this entry point .                                                                                         |


### 2.3 Software Architecture (Hexagonal Design)

Unlike typical simple Lambda scripts, this project implements a robust **Hexagonal Architecture** (Ports and Adapters) to ensure maintainability, testability, and clean separation of concerns.

-   **Domain Layer (`src/domain`)**: Contains the core business rules and interface definitions (Ports). This layer is pure and has **zero dependencies** on external frameworks or AWS SDKs.
-   **Application Layer (`src/application`)**: Contains the use cases (e.g., `RecognizeCelebrity`). It orchestrates the logic by communicating with the Domain and Infrastructure layers through interfaces.
-   **Infrastructure Layer (`src/infrastructure`)**: Contains the "Adapters" (e.g., `S3Adapter`, `RekognitionAdapter`) that implement the domain interfaces. This is the **only** place where AWS SDKs are imported.
-   **Composition Root (`src/index.ts`)**: The entry point that "wires" everything together, injecting specific infrastructure adapters into the application use cases.


This design proves that the solution is not just a script, but a well-engineered software application ready for extension and testing.

### 2.4 Architecture Diagram

The following diagram visualizes the **Hexagonal Architecture** and the data flow:

![alt text](<docs/AWS Rekognition Celebrity-Diagram.png>)
---

## 3. Deployment and Operation Overview

The deployment process is highly streamlined to meet the requirement for full automation (Gütestufe 3 for Automation):

1.  **Preparation:** Clone this Git repository.
2.  **Provisioning:** Execute the single `Init.sh` script. This script uses the AWS CLI to create the S3 buckets, configure IAM roles, deploy the Lambda function code (written in TypeScript/Node.js), and set up the S3 trigger and permissions.
3.  **Testing:** Execute the `Test-Script`. This script verifies functionality by uploading a test photo, waiting for the Lambda function to process it via AWS Rekognition, downloading the resulting JSON file, and displaying the recognized name and match confidence.
4.  **Traceability:** All configurations and changes are tracked within Git.

---

## 4. Project Organization

### 4.1 Task Distribution (Aufgabenverteilung)

The project tasks were distributed among the team members as follows (Weighting based on B2):

| Task / Activity | Responsible Person | Status |
| :--- | :--- | :--- |
| **Project Conception & Planning** | *Dima* | Done |
| **AWS Infrastructure (Init.sh)** | *Julian* | Done |
| **Use Case Implementation (TypeScript)** | *Dima & Julian* | Done |
| **Documentation (Markdown)** | *Julian & Dima* | Done |
| **Testing & verification** | *Julian* | Done |

### 4.2 Reflexion

#### Dima

> *Der schwierigste Teil des Projekts bestand darin, alle vorliegenden Informationen in eine klare Architektur umzusetzen. Ich hatte keine klare Vorstellung davon, wo ich anfangen sollte. Ich musste in einer realen Situation viele neue Dinge lernen, wie AWS CLI, IAM-Rollen, S3-Buckets, Lambda-Funktionen und so weiter. Die eigentliche Umsetzung war für mich nicht so schwer, da ich bereits über fundierte Erfahrungen mit TypeScript und Node.js verfüge. Für das nächste Projekt würde ich mir mehr Zeit für die initiale Planung der IAM-Berechtigungen nehmen, um 'AccessDenied' Fehler früher zu vermeiden.*

#### Julian

> *Für mich war es ein sehr interessantes Projekt. Ich musste auch viel Neues lernen. Es ist eine Sache, alles in der Theorie zu wissen, aber eine andere, es in der Praxis anzuwenden. Es war auch interessant zu sehen, wie die Architektur in der Praxis funktioniert. Ich habe auch etwas über die hexagonale Architektur gelernt und wie sie in einem realen Projekt umgesetzt werden kann. Beim nächsten Mal würde ich die Test-Automatisierung früher aufsetzen, um manuelles Testen während der Entwicklung zu reduzieren.*

---

## 5. Sources

The following documentation and resources were used during the development of this project:

*   **AWS Documentation**:
    *   [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/)
    *   [Amazon Rekognition Documentation](https://docs.aws.amazon.com/rekognition/)
    *   [Amazon S3 Documentation](https://docs.aws.amazon.com/s3/)
    *   [AWS CLI Command Reference](https://awscli.amazonaws.com/v2/documentation/api/latest/index.html)
*   **Architecture**:
    *   [Hexagonal Architecture (Ports and Adapters)](https://alistair.cockburn.us/hexagonal-architecture/)
    *   [Building Serverless Applications with Hexagonal Architecture](https://aws.amazon.com/blogs/compute/developing-evolutionary-architecture-with-aws-lambda/)