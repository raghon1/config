function FindProxyForURL(url, host) {
 if (shExpMatch(url, "*uio.no*")) { return "SOCKS localhost:20000 ; DIRECT"; }
 if (shExpMatch(url, "*cmz.nsc.no*")) { return "SOCKS localhost:24000"; }
 if (shExpMatch(url, "*nsc.no*")) { return "SOCKS localhost:30000"; }
 // direct for everything else
 return "DIRECT";
}
