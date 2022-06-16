/*
 Navicat Premium Data Transfer

 Source Server         : tremote
 Source Server Type    : SQLite
 Source Server Version : 2008017
 Source Schema         : main

 Target Server Type    : SQLite
 Target Server Version : 2008017
 File Encoding         : 65001

 Date: 12/06/2022 13:28:54
*/

PRAGMA foreign_keys = false;

-- ----------------------------
-- Table structure for servers
-- ----------------------------
DROP TABLE "servers";
CREATE TABLE "servers" (
  "id" INTEGER(11) NOT NULL,
  "name" TEXT,
  "type" TEXT,
  "ip" TEXT,
  "port" TEXT,
  "username" TEXT,
  "password" TEXT,
  PRIMARY KEY ("id")
);

PRAGMA foreign_keys = true;
