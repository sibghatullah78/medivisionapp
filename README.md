# MediVision – AI-Powered Prescription Reader

## 📌 Introduction

With the advancement of Artificial Intelligence (AI) and Computer Vision, healthcare systems are evolving to automate tasks like prescription reading and medicine recognition. However, existing solutions often fail to handle handwritten prescriptions accurately.

## 📱 Project Summary

**MediVision** is a cross-platform mobile application that digitizes handwritten medical prescriptions using an intelligent AI pipeline. It uses:

- **PaddleOCR** to detect medicine regions in scanned prescriptions,
- A **Vision Transformer (ViT)** model trained on handwritten medicine names to perform OCR,
- **GPT-4o** to correct and refine noisy or misspelled text using contextual understanding.

The app allows users to:
- Create profiles,
- Scan and extract medicine names from prescriptions,
- View medical usage,
- Save and manage prescriptions for future reference.

The system was evaluated against traditional models like LSTM, RCNN, and Faster-RCNN, with GPT-4o chosen for its superior accuracy and language reasoning. MediVision contributes to the digital healthcare transformation by making handwritten prescription processing intelligent, accessible, and reliable.
