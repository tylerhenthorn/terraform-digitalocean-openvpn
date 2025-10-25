terraform { 
  cloud { 
    
    organization = "TylerHenthorn" 

    workspaces { 
      name = "openvpn-server" 
    } 
  } 
}