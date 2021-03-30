import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Global variables go here
const activeColor = Color(0xFF4c8c80);

// Initializing firestore for the whole app
final db = Firestore.instance;