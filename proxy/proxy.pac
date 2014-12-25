function FindProxyForURL(url, host) {
 if (shExpMatch(url, "*uio.no*")) { return "SOCKS localhost:20000 ; DIRECT"; }
 if (shExpMatch(url, "*tsd.usit.no*")) { return "SOCKS localhost:29000"; }
 if (shExpMatch(url, "*cmz.nsc.no*")) { return "SOCKS localhost:24000"; }
 if (shExpMatch(url, "*nsc.no*")) { return "SOCKS localhost:30001"; }
 if (shExpMatch(url, "*netflix.com*")) { return "SOCKS 10.0.1.189:9150"; DIRECT }
 if (shExpMatch(url, "*hulu.com*")) { return "SOCKS 10.0.1.189:9150"; DIRECT }
 // direct for everything else
 return "DIRECT";
}
