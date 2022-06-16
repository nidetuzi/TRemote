

import 'dart:io';

String Separator(){
  if(Platform.isWindows){
    return "\\";
  }else{
    return "/";
  }
}