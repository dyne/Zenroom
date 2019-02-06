/*
Licensed to the Apache Software Foundation (ASF) under one
or more contributor license agreements.  See the NOTICE file
distributed with this work for additional information
regarding copyright ownership.  The ASF licenses this file
to you under the Apache License, Version 2.0 (the
"License"); you may not use this file except in compliance
with the License.  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing,
software distributed under the License is distributed on an
"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
KIND, either express or implied.  See the License for the
specific language governing permissions and limitations
under the License.
*/

/* AMCL X.509 Functions */

/* Build executible after installation:

  gcc -std=c99 -g ./testx509.c -I/opt/amcl/include -L/opt/amcl/lib -lamcl_x509 -lamcl_curve -lamcl_core -o testx509

*/

#include <stdio.h>
#include "ecdh.h"
#include "rsa.h"
#include "x509.h"

// Supported Encryption Methods
#define ECC 1
#define RSA 2

#define H256 2
#define H384 3
#define H512 4

// countryName
static char cn[3]= {0x55,0x04,0x06};
static octet CN= {3,sizeof(cn),cn};

// stateName
// static char sn[3]= {0x55,0x04,0x08};
// static octet SN= {3,sizeof(sn),sn};

// localName
// static char ln[3]= {0x55,0x04,0x07};
// static octet LN= {3,sizeof(ln),ln};

// orgName
static char on[3]= {0x55,0x04,0x0A};
static octet ON= {3,sizeof(on),on};

// unitName
// static char un[3]= {0x55,0x04,0x0B};
// static octet UN= {3,sizeof(un),un};

// myName
// static char mn[3]= {0x55,0x04,0x03};
// static octet MN= {3,sizeof(mn),mn};

// emailName
static char en[9]= {0x2a,0x86,0x48,0x86,0xf7,0x0d,0x01,0x09,0x01};
static octet EN= {9,sizeof(en),en};

void print_out(char *des,octet *c,int index,int len)
{
    int i;
    printf("%s [",des);
    for (i=0; i<len; i++)
        printf("%c",c->val[index+i]);
    printf("]\n");
}

void print_date(char *des,octet *c,int index)
{
    int i=index;
    printf("%s [",des);
    if (i==0) printf("]\n");
    else printf("20%c%c-%c%c-%c%c %c%c:%c%c:%c%c]\n",c->val[i],c->val[i+1],c->val[i+2],c->val[i+3],c->val[i+4],c->val[i+5],c->val[i+6],c->val[i+7],c->val[i+8],c->val[i+9],c->val[i+10],c->val[i+11]);
}

/* test driver program */
// Sample Certs. Uncomment one CA cert and one example cert. Note that AMCL library must be built to support given curve.
// Sample Certs all created using OpenSSL - see http://blog.didierstevens.com/2008/12/30/howto-make-your-own-cert-with-openssl/
// Note - SSL currently only supports NIST curves. Howevever version 1.1.0 of OpenSSL now supports C25519

#if CHOICE==C25519
// ** CA is RSA 2048-bit based - for use with C25519 build of the library - assumes use of SHA256 in Certs

char ca_b64[]="MIID6zCCAtOgAwIBAgIJALJxywTGMUA7MA0GCSqGSIb3DQEBCwUAMIGLMQswCQYDVQQGEwJJRTEQMA4GA1UECAwHSXJlbGFuZDEPMA0GA1UEBwwGRHVibGluMQ8wDQYDVQQKDAZNSVJBQ0wxDTALBgNVBAsMBGxhYnMxEzARBgNVBAMMCk1pa2UgU2NvdHQxJDAiBgkqhkiG9w0BCQEWFW1pa2Uuc2NvdHRAbWlyYWNsLmNvbTAeFw0xNjA2MzAxNzQyNDFaFw0yMTA2MzAxNzQyNDFaMIGLMQswCQYDVQQGEwJJRTEQMA4GA1UECAwHSXJlbGFuZDEPMA0GA1UEBwwGRHVibGluMQ8wDQYDVQQKDAZNSVJBQ0wxDTALBgNVBAsMBGxhYnMxEzARBgNVBAMMCk1pa2UgU2NvdHQxJDAiBgkqhkiG9w0BCQEWFW1pa2Uuc2NvdHRAbWlyYWNsLmNvbTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAPCTPcPWgiI0ka5Czd0ZzW+gTaMEe9QW7FGu5+9fS6ALrCpdbxdwDX8+OQXZuQJpLYEAIq1pDh3fVQguH/jUM9gQQrS2Lmz3KhXC/J3yv85FRotCGv13ztapMedTy2IxzbtPvoQQc+IAlUPX6DtD8JqBoAstrlQUnkMChKztMGR2OERdjNzXmXm+KMMPlZzk+EvRwCornVA+SB5QAWj7y/3ISFo0y1WG8ewoQEx3HQYrjXbQP1VTdiLW7dHPQP86XKoTMtTBEYWuFhKB9ClCeu4Qqqxqa9UPIVfdro7SoZScCt+OX4KhzLnOCFupoLxE+yTDhDpYcCcmI1yglCv9DpMCAwEAAaNQME4wHQYDVR0OBBYEFFH18YEMoxms7121N/nQ+Wm3b5smMB8GA1UdIwQYMBaAFFH18YEMoxms7121N/nQ+Wm3b5smMAwGA1UdEwQFMAMBAf8wDQYJKoZIhvcNAQELBQADggEBALCUob0y2O4DSzsqG76yrtCxXWxDdgjSkHKzwFK62BzZK5EuCDJrVgCyoLX0SvYvoT9x0wtS+bxJ7TNEGn7Rkp5/iSQCUSF7sVRoHqzErk70xVKKDy5FS+zre8k08nJrtRg2u1PmY95NO1SE96BtUVLs+8rQuqEX283tqlmqE/SF2+lxOb0WaVrya4oCJfj/XT83pRTcd5w9i7huWltMbKbagkmlQ/5q9Ayp/Jh1lLXmxr+/xEbZ2xEop/y+mgVF0vLxap7R5toBA0Yk7vvirlYv0hZGqGi5lBc9VeUqm1H/7XCi5xRU3AtJ4QRk4Z1xUa4qAPKfiqlPKd1dVe3Ah3w=";

// an ECC 255-bit CA-signed cert
char cert_b64[]="MIICqjCCAZICCQCk9jKdJYtnjDANBgkqhkiG9w0BAQsFADCBizELMAkGA1UEBhMCSUUxEDAOBgNVBAgMB0lyZWxhbmQxDzANBgNVBAcMBkR1YmxpbjEPMA0GA1UECgwGTUlSQUNMMQ0wCwYDVQQLDARsYWJzMRMwEQYDVQQDDApNaWtlIFNjb3R0MSQwIgYJKoZIhvcNAQkBFhVtaWtlLnNjb3R0QG1pcmFjbC5jb20wHhcNMTYwNjMwMTc0NjQ4WhcNMTYwNzMwMTc0NjQ4WjCBjDELMAkGA1UEBhMCSUUxEDAOBgNVBAgMB0lyZWxhbmQxDzANBgNVBAcMBkR1YmxpbjEPMA0GA1UECgwGTUlSQUNMMQ0wCwYDVQQLDARsYWJzMRgwFgYDVQQDDA9LZWFsYW4gTWNDdXNrZXIxIDAeBgkqhkiG9w0BCQEWEWtlYWxhbkBtaXJhY2wuY29tMDkwFAYHKoZIzj0CAQYJKwYBBAHaRw8BAyEASiRQmhO9PP+SqodOhXYrnSlcyAOog63E6a4KLDFvAzEwDQYJKoZIhvcNAQELBQADggEBALByfCM/EhdqWBrEnDHtH2/U8xr1eSylHdcfnDSDR+X6KXH5rIJ/397lZQMHB6QSsEiVrWzfFDFPPjDN3xEDsZw09ZTT+L8Wi5P3UKR1gtawQCx3ciKEywAU1CU2dV05gvyebqIsbFUyH7jOlj6/1hIx9zaiLcoEex6D55MYQuWo664HF3CNdJFk1k4HF+fclRhyl4iryp0F9p0Wl5vyn96kg0NwaBZG860oCWDHZsjRq1JeSSaRf9CKNXWbQwjByeEcDphpprqmoVcI60cC0TvZZm1x4y7vjCXLD6uCDw3P7fnSp40yce64+IKUr8/cS+QYus58KHdLaLXsojZHL3c=";
#endif

#if CHOICE==NIST256

// ** CA is RSA 2048-bit based - for use with NIST256 build of library - assumes use of SHA256 in Certs
// RSA 2048 Self-Signed CA cert
char ca_b64[]="MIIDuzCCAqOgAwIBAgIJAP44jcM1MOROMA0GCSqGSIb3DQEBCwUAMHQxCzAJBgNVBAYTAklFMRAwDgYDVQQIDAdJcmVsYW5kMQ8wDQYDVQQHDAZEdWJsaW4xITAfBgNVBAoMGEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZDEfMB0GCSqGSIb3DQEJARYQbXNjb3R0QGluZGlnby5pZTAeFw0xNTExMjYwOTUwMzlaFw0yMDExMjUwOTUwMzlaMHQxCzAJBgNVBAYTAklFMRAwDgYDVQQIDAdJcmVsYW5kMQ8wDQYDVQQHDAZEdWJsaW4xITAfBgNVBAoMGEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZDEfMB0GCSqGSIb3DQEJARYQbXNjb3R0QGluZGlnby5pZTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBANUs7/nri9J8zw8rW8JVszXP0ZqeLoQJaq2X28ebm8x5VT3okr9rnBjFjpx0YKQCAFQf8iSOOYuNpDvtZ/YpsjPbk2rg5sLY9G0eUMqrTuZ7moPSxnrXS5evizjD9Z9HqaqeNEYD3sPouPg+lhU1oAUQjUTJVFhEr1x0EnSEYbbrWtY9ZDSuZv+d4NIeqqPOYFd1yZc+LYZyQbAAQqwRLNPZH/rnIykLa6I7w7mGT7H6SBz2O09BtgpTHhalL40ecXa4ZOEze0xwzlc+mEFIrnmdadg3vQrJt42RVbo3LN6RfDIqUZOMOtQW/53pUR1lIpCwVWJTiOpmSEIEqhhjFq0CAwEAAaNQME4wHQYDVR0OBBYEFJrz6LHeT6FcjRahpUC3hAMxKRTCMB8GA1UdIwQYMBaAFJrz6LHeT6FcjRahpUC3hAMxKRTCMAwGA1UdEwQFMAMBAf8wDQYJKoZIhvcNAQELBQADggEBADqkqCYVa3X8XO9Ufu6XIUoZafFPRjSeJXvEIWqlbm7ixJZ2FPOvf2eMc5RCZYigNKhsxru5Ojw0lPcpa8DDmEsdZDf7p0vlmf7T7xH9gtoInh4DzgI8HRHFc8R/z2/jLX7nlLoopKX5yp7F1gRACg0pd4tGpQ6EnBNcYZZghFH9UIRDmx+vDlwDCu8vyRPt35orrEiI4XGq/QkvxxAb5YWxQ4i06064ULfyCI7suu3KoobdM1aAaA8zhpOOBXKbq+Wi9IGFe/wiEMHLmfHdt9CBTjIWb//IHji4RT05kCmTVrx97pb7EHafuL3L10mM5cpTyBWKnb4kMFtx9yw+S2U=";
// an RSA 2048 CA-signed cert
//char cert_b64[]="MIIDcjCCAloCAQEwDQYJKoZIhvcNAQELBQAwdDELMAkGA1UEBhMCSUUxEDAOBgNVBAgMB0lyZWxhbmQxDzANBgNVBAcMBkR1YmxpbjEhMB8GA1UECgwYSW50ZXJuZXQgV2lkZ2l0cyBQdHkgTHRkMR8wHQYJKoZIhvcNAQkBFhBtc2NvdHRAaW5kaWdvLmllMB4XDTE1MTEyNjEwMzQzMFoXDTE3MTEyNTEwMzQzMFowgYkxCzAJBgNVBAYTAklFMRAwDgYDVQQIDAdJcmVsYW5kMQ8wDQYDVQQHDAZEdWJsaW4xETAPBgNVBAoMCENlcnRpVm94MQ0wCwYDVQQLDARMYWJzMQ0wCwYDVQQDDARNSUtFMSYwJAYJKoZIhvcNAQkBFhdtaWtlLnNjb3R0QGNlcnRpdm94LmNvbTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMIoxaQHFQzfyNChrw+3i7FjRFMHZ4zspkjkAcJW21LdBCqrxU+sdjyBoSFlrlafQOHshbrEP93AKX1bfaYbuV4fzq7OlRaLxaK+b+xrOJdewMI2WZ5OwEzj3onZATISogIoB6dTdzJ41NuxuMqQ/DqOnVrRA0SoIespbQhB8FGHBLw0hJATBzUk+bqOIt0HmnMp2EbYgtuG4lYINU/lD3Qt16SunUukWRLtxqJkioie+dkhP2zm+bOlSVmeQb4Wp8AI14OKkTfkdYC8qCxb5eabg90Q33rQUhNwRQHhHwopZwD/BgodasoSrPfwUlj0awh6y87eMGcik5Q/mjkCk5MCAwEAATANBgkqhkiG9w0BAQsFAAOCAQEAFrd7R/67ClkbLhpiX++6QTOa47siUAB9v+Qil9hZfhPNeeM589ixYkD4zH5pOK2B0ea+CXEKkanQ6lXx9KV86yS7fq6Yww7wO0diecusHd0+P82i46Tq0nm8nlsnAuhYoFRUGa2m2DkB1HSsB0ts8DjzFLySonFjSSLHDU0ox9/uFbJMzipy3ijAA4XM0N4jRrUfrmxpA7DOOsbEbGkvvB7VK9+s9PHE/4dJTwhSteplUnhxVFkkDo/JwaLx4/IEQRlCF3KEQ5s3AwRHnbrIjOY2yONxHBtJEp7QN5aOHruwvMNRNheCBPiQJyLitUsFGr4voANmobkrFgYtu0tRMQ==";
// an ECC 256 CA-signed cert
char cert_b64[]="MIICojCCAYoCAQMwDQYJKoZIhvcNAQELBQAwdDELMAkGA1UEBhMCSUUxEDAOBgNVBAgMB0lyZWxhbmQxDzANBgNVBAcMBkR1YmxpbjEhMB8GA1UECgwYSW50ZXJuZXQgV2lkZ2l0cyBQdHkgTHRkMR8wHQYJKoZIhvcNAQkBFhBtc2NvdHRAaW5kaWdvLmllMB4XDTE1MTEyNjEzNDcyOVoXDTE3MTEyNTEzNDcyOVowgYQxCzAJBgNVBAYTAklFMRAwDgYDVQQIDAdJcmVsYW5kMQ8wDQYDVQQHDAZEdWJsaW4xETAPBgNVBAoMCENlcnRpdm94MQ0wCwYDVQQLDARMYWJzMQ8wDQYDVQQDDAZtc2NvdHQxHzAdBgkqhkiG9w0BCQEWEG1zY290dEBpbmRpZ28uaWUwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAATO2iZiQZsXxzwBKnufKfZcsctNXZ4PmfJm638PmX9DQ3Xdb+nD5VxiOakNcB9xf5im8CriiOF5Z/7yPGyzUMbdMA0GCSqGSIb3DQEBCwUAA4IBAQAK5fMgGCCiPts8hMUZvYDpu8hd7qtPKPBc10QUccHb7PGrhqf/Ex2Gpj1aaURmx7SGZG0HX97LtkdW8KQpEoyaa60r7cjVA589TznxXKSGg5ggVoFJNpuZUm7VcolLjwIgTxtGbPzrvVMiZ4cl4PwFePXVKTl4f8XkOFX5gLmVSuCf729lEBmpx3IzqGmTjmnBixaApUElOKVeL7hiUKP3TqMUxZN+QNJBq4Mh9K9h4Sks2oneLwBwhMqQvpmcOb/7SucJn5N0IgJoGaMbfX0oCJJID1NSbagUSbFD1XciR2Ng9VtvnRP+htmEQ7jtww8phFdrWt5M5zPGOHUppqDx";

// ** CA is ECC 256 based  - for use with NIST256 build of library
// ECC 256 Self-Signed CA cert
//char ca_b64[]="MIIB7TCCAZOgAwIBAgIJANp4nGS/VYj2MAoGCCqGSM49BAMCMFMxCzAJBgNVBAYTAklFMRAwDgYDVQQIDAdJcmVsYW5kMQ8wDQYDVQQHDAZEdWJsaW4xITAfBgNVBAoMGEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZDAeFw0xNTExMjYxMzI0MTBaFw0yMDExMjUxMzI0MTBaMFMxCzAJBgNVBAYTAklFMRAwDgYDVQQIDAdJcmVsYW5kMQ8wDQYDVQQHDAZEdWJsaW4xITAfBgNVBAoMGEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZDBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABPb6IjYNKyfbEtL1aafzW1jrn6ALn3PnGm7AyX+pcvwG0GKmb3Z/uHzhT4GysNE0/GB1n4Y/mrORQIm2X98rRs6jUDBOMB0GA1UdDgQWBBSfXUNkgJVklIhuXq4DCnVYhsdzwDAfBgNVHSMEGDAWgBSfXUNkgJVklIhuXq4DCnVYhsdzwDAMBgNVHRMEBTADAQH/MAoGCCqGSM49BAMCA0gAMEUCIQDrZJ1tshwTl/jabU2i49EOgbWe0ZgE3QZywJclf5IVwwIgVmz79AAf7e098lyrOKYAqbwjHVyMZGfmkNNGIuIhp/Q=";
// an ECC 256 CA-signed cert
//char cert_b64[]="MIIBvjCCAWQCAQEwCgYIKoZIzj0EAwIwUzELMAkGA1UEBhMCSUUxEDAOBgNVBAgMB0lyZWxhbmQxDzANBgNVBAcMBkR1YmxpbjEhMB8GA1UECgwYSW50ZXJuZXQgV2lkZ2l0cyBQdHkgTHRkMB4XDTE1MTEyNjEzMjc1N1oXDTE3MTEyNTEzMjc1N1owgYIxCzAJBgNVBAYTAklFMRAwDgYDVQQIDAdJcmVsYW5kMQ8wDQYDVQQHDAZEdWJsaW4xETAPBgNVBAoMCENlcnRpdm94MQ0wCwYDVQQLDARMYWJzMQ0wCwYDVQQDDARtaWtlMR8wHQYJKoZIhvcNAQkBFhBtc2NvdHRAaW5kaWdvLmllMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEY42H52TfWMLueKB1o2Sq8uKaKErbHJ2GRAxrnJdNxex0hxZF5FUx7664BbPUolKhpvKTnJxDq5/gMqXzpKgR6DAKBggqhkjOPQQDAgNIADBFAiEA0ew08Xg32g7BwheslVKwXo9XRRx4kygYha1+cn0tvaUCIEKCEwnosZlAckjcZt8aHN5zslE9K9Y7XxTErTstthKc";
// an RSA 2048 CA-signed cert
//char cert_b64[]="MIICiDCCAi4CAQIwCgYIKoZIzj0EAwIwUzELMAkGA1UEBhMCSUUxEDAOBgNVBAgMB0lyZWxhbmQxDzANBgNVBAcMBkR1YmxpbjEhMB8GA1UECgwYSW50ZXJuZXQgV2lkZ2l0cyBQdHkgTHRkMB4XDTE1MTEyNjEzMzcwNVoXDTE3MTEyNTEzMzcwNVowgYExCzAJBgNVBAYTAklFMQ8wDQYDVQQIDAZJZWxhbmQxDzANBgNVBAcMBkR1YmxpbjERMA8GA1UECgwIQ2VydGl2b3gxDTALBgNVBAsMBExhYnMxDTALBgNVBAMMBE1pa2UxHzAdBgkqhkiG9w0BCQEWEG1zY290dEBpbmRpZ28uaWUwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCjPBVwmPg8Gwx0+8xekmomptA0BDwS7NUfBetqDqNMNyji0bSe8LAfpciU7NW/HWfUE1lndCqSDDwnMJmwC5e3GAl/Bus+a+z8ruEhWGbn95xrHXFkOawbRlXuS7UcEQCvPr8KQHhNsg4cyV7Hn527CPUl27n+WN8/pANo01cTN/dQaK87naU0Mid09vktlMKSN0zyJOnc5CsaTLs+vCRKJ9sUL3d4IQIA2y7gvrTe+iY/QI26nqhGpNWYyFkAdy9PdHUEnDI6JsfF7jFh37yG7XEgDDA3asp/oi1T1+ZoASj2boL++opdqCzDndeWwzDWAWuvJ9wULd80ti6x737ZAgMBAAEwCgYIKoZIzj0EAwIDSAAwRQIgCDwgl98+9moBo+etaLt8MvB/z5Ti6i9neRTZkvoFl7YCIQDq//M3OB757fepErRzIQo3aFAFYjOooi6WdSqP3XqGIg==";

#endif

#if CHOICE==NIST384

// ** CA is RSA 3072-bit based  - for use with NIST384 build of library - assumes use of SHA384 in Certs
// RSA 3072 Self-Signed CA cert
char ca_b64[]="MIIElzCCAv+gAwIBAgIJAJA+8OyEeK4FMA0GCSqGSIb3DQEBDAUAMGIxCzAJBgNVBAYTAklFMRAwDgYDVQQIDAdJcmVsYW5kMQ8wDQYDVQQHDAZEdWJsaW4xITAfBgNVBAoMGEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZDENMAsGA1UEAwwETWlrZTAeFw0xNTExMjYxNDQ0MDBaFw0yMDExMjUxNDQ0MDBaMGIxCzAJBgNVBAYTAklFMRAwDgYDVQQIDAdJcmVsYW5kMQ8wDQYDVQQHDAZEdWJsaW4xITAfBgNVBAoMGEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZDENMAsGA1UEAwwETWlrZTCCAaIwDQYJKoZIhvcNAQEBBQADggGPADCCAYoCggGBANvNO8ahsanxzqwkp3A3bujwObJoP3xpOiAAxwGbW867wx4EqBjPRZP+Wcm9Du6e4Fx9U7tHrOLocIUUBcRrmxUJ7Z375hX0cV9yuoYPNv0o2klJhB8+i4YXddkOrSmDLV4r46Ytt1/gjImziat6ZJALdd/uIuhaXwjzy1fFqSEBpkzhrFwFP9MG+5CgbRQed+YxZ10l/rjk+h3LKq9UFsxRCMPYhBFgmEKAVTMnbTfNNxawTRCKtK7nxxruGvAEM+k0ge5rvybERQ0NxtizefBSsB3Q6QVZOsRJiyC0HQhE6ZBHn4h3A5nHUZwPeh71KShw3uMPPB3Kp1pb/1Euq8azyXSshEMPivvgcGJSlm2b/xqsyrT1tie82MqB0APYAtbx3i5q8p+rD143NiNO8fzCq/J+EV82rVyvqDxf7AaTdJqDbZmnFRbIcrLcQdigWZdSjc+WxrCeOtebRmRknuUmetsCUPVzGv71PLMUNQ2qEiq8KGWmnMBJYVMl96bPxwIDAQABo1AwTjAdBgNVHQ4EFgQUsSjrHeZ5TNI2tMcQd6wUnFpU8DcwHwYDVR0jBBgwFoAUsSjrHeZ5TNI2tMcQd6wUnFpU8DcwDAYDVR0TBAUwAwEB/zANBgkqhkiG9w0BAQwFAAOCAYEADlnC1gYIHpVf4uSuBpYNHMO324hhGajHNraHYQAoYc0bW4OcKi0732ib5CHDrV3LCxjxF4lxZVo61gatg5LnfJYldXc0vP0GQRcaqC6lXlLb8ZJ0O3oPgZkAqpzc+AQxYW1wFxbzX8EJU0stSwAuxkgs9bwg8tTxIhDutrcjQl3osnAqGDyM+7VAG5QLRMzxiZumyD7s/xBUOa+L6OKXf4QRr/SH/rPU8H+ENaNkv4PApSVzCgTBPOFBIzqEuO4hcQI0laUopsp2kK1w6wYB5oY/rR/O6lNNfB2WEtfdIhdbQru4cUE3boKerM8Mjd21RuerAuK4X8cbDudHIFsaopGSNuzZwPo/bu0OsmZkORxvdjahHJ0G3/6jM6nEDoIy6mXUCGOUOMhGQKCa8TYlZdPKz29QIxk6HA1wCA38MxUo/29Z7oYw27Mx3x8Gcr+UA4vc+oBN3IEzRmhRZKAYQ10MhYPx3NmYGZBDqHvT06oG5hysTCtlVzx0Tm+o01JQ";
// an RSA 3072 CA-signed cert
//char cert_b64[]="MIIEWzCCAsMCAQYwDQYJKoZIhvcNAQEMBQAwYjELMAkGA1UEBhMCSUUxEDAOBgNVBAgMB0lyZWxhbmQxDzANBgNVBAcMBkR1YmxpbjEhMB8GA1UECgwYSW50ZXJuZXQgV2lkZ2l0cyBQdHkgTHRkMQ0wCwYDVQQDDARNaWtlMB4XDTE1MTEyNjE0NDY0MloXDTE3MTEyNTE0NDY0MlowgYQxCzAJBgNVBAYTAklFMRAwDgYDVQQIDAdJcmVsYW5kMQ8wDQYDVQQHDAZEdWJsaW4xETAPBgNVBAoMCENlcnRpdm94MQ0wCwYDVQQLDARMYWJzMQ8wDQYDVQQDDAZtc2NvdHQxHzAdBgkqhkiG9w0BCQEWEG1zY290dEBpbmRpZ28uaWUwggGiMA0GCSqGSIb3DQEBAQUAA4IBjwAwggGKAoIBgQC6SrDiE4BpTEks1YpX209q8iH0dfvhGO8hi1rGYFYnz+eeiOvPdXiCdIPVPbGwxQGMEnZQV1X0KupYJw3LR2EsXhN4LZBxnQZmDvUXsTU+Ft/CKZUxVoXpNMxzwl70RC6XeUpPxvdPXa78AnfLL/DsOKsxCfNaKYZZ6G53L6Y69+HrCbyM7g2KrZ9/K/FXS1veMpRj9EbA6Mcdv1TUDNK2fTDV952AQO3kC3+PqywdVgPvntraAoQomrni+tcFW7UXe2Sk7DRcF/acBSuo2UtP3m9UWNL+8HOXvtRqmhns55Vj4DxKuPln759UBS7WZ11apCvC3BvCHR/k3WRf9PQWnW2cmT73/kEShvTRi8h7F9RWvYTEF1MuwSVy+l51q8O3rJU4XxnLm/YbtIGXZUf5Rqb0985zQkA+6rip/OSc8X5a3OV3kp38U7tXJ5sqBMg9RdIIz42cmiRLG5NYSj0/T6zjYEdwj3SYEBoPN/7UGSmhu8fdxS7JYPNpOsgeiu8CAwEAATANBgkqhkiG9w0BAQwFAAOCAYEAyxxEg0hWLFuN2fiukX6vqzSDx5Ac8w1JI4W/bamRd7iDZfHQYqyPDZi9s07I2PcGbByj2oqoyGiIEBLbsljdIEF4D229h2kisn1gA9O+0IM44EgjhBTUoNDgC+SbfJrXlU2GZ1XI3OWjbK7+1wiv0NaBShbbiPgSdjQBP8S+9W7lyyIrZEM1J7maBdepie1BS//DUDmpQzEi0UlB1J+HmQpyZsnT97J9uIPKsK4t2/+iOiknl6iS4GzAQKMLqj2yIBRf/O44ZZ6UZIKLtI4PCVS/8H5Lrg3AC0kr4ZkPAXzefUiTwyLVkqYSxSSTvtb3BpgOxIbmA6juFid0rvUyjN4fuDQkxl3PZyQwIHjpz33HyKrmo4BZ8Dg4JT8LCsQgd0AaD3r0QOS5FdLhkb+rD8EMSsCoOCEtPI6lqLJCrGOQWj7zbcUdPOEsczWMI9hSfK3u/P9+gOUBUFkb0gBIn3WvNuHifIHpsZ5bzbR+SGtu5Tgc7CCCPyNgz1Beb247";
// an ECC 384 CA-signed cert
char cert_b64[]="MIIDCDCCAXACAQcwDQYJKoZIhvcNAQEMBQAwYjELMAkGA1UEBhMCSUUxEDAOBgNVBAgMB0lyZWxhbmQxDzANBgNVBAcMBkR1YmxpbjEhMB8GA1UECgwYSW50ZXJuZXQgV2lkZ2l0cyBQdHkgTHRkMQ0wCwYDVQQDDARNaWtlMB4XDTE1MTEyNjE1MzU1M1oXDTE3MTEyNTE1MzU1M1owYDELMAkGA1UEBhMCSUUxEDAOBgNVBAgMB0lyZWxhbmQxDzANBgNVBAcMBkR1YmxpbjEQMA4GA1UECgwHQ2VydGl2bzENMAsGA1UECwwETGFiczENMAsGA1UEAwwEbWlrZTB2MBAGByqGSM49AgEGBSuBBAAiA2IABJ1J+FT5mxxYEM4aYKM0CvZHmh8JFXzoBmzibabrvyTz79+1QOrR+6MEEsKtmJIYPJi+GsQ0PmjF2HmJncM1zeQh7DQYJf2Xc8p5Vjd8//6YREBVfN3UIyrl87MSucy+mjANBgkqhkiG9w0BAQwFAAOCAYEAmuwa64+K1qlCELpcnCyWwMhSb+Zsw0Hh6q/BfxalZhsX1UFEwE9nHoVJcokaEEYF4u4AYXU5rdysRHxYBfgMbohguTT7sJwCfve2JqpqvhQOkGDG1DB4Ho4y7NPPYB2+UMd7JMD0TOcHXdgQ8FtAE0ClD8VkW0gAC0lCrbQbynfLoUjIWqg3w2g79hvdZPgRt208nFiHuezynOaEFePoXl8CxHInsxAnMaJn2fEs5/QH67pwD65mPdNFsvlr0zdzYcceqEmEHpRAXFOQAJtffGjWAGGX/CsghLuqlpdCiTGA1B53XoXKJvArr/kHpTNMsU1NnkQIHZ5n4USCo4QgL6n9nwem7U2mYBYjmxPi5Y3JJnTZz4zUnv0bD0vSwoivnFZox9H6qTAkeIX1ojJ2ujxWHNOMvOFb6nU2gqNZj2vYcO38OIrK9gwM9lm4FF20YBufh+WOzQthrHJv0YuQt3NuDQEMkvz+23YvzZlr+e2XqDlMhyR01Kk0MXeLGGcv";

// ** CA is ECC 384 based - - for use with NIST384 build of library - assumes use of SHA384 in Certs
// ECC 384 Self-Signed CA Cert
//char ca_b64[]="MIICSTCCAc6gAwIBAgIJAIwHpOFSZLXnMAoGCCqGSM49BAMDMGIxCzAJBgNVBAYTAklFMRAwDgYDVQQIDAdJcmVsYW5kMQ8wDQYDVQQHDAZEdWJsaW4xITAfBgNVBAoMGEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZDENMAsGA1UEAwwEbWlrZTAeFw0xNTExMjYxNTQ0NTlaFw0yMDExMjUxNTQ0NTlaMGIxCzAJBgNVBAYTAklFMRAwDgYDVQQIDAdJcmVsYW5kMQ8wDQYDVQQHDAZEdWJsaW4xITAfBgNVBAoMGEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZDENMAsGA1UEAwwEbWlrZTB2MBAGByqGSM49AgEGBSuBBAAiA2IABOEPMYBqzIn1hJAMZ0aEVxQ08gBF2aSfWtEJtmKj64014w7VfWdeFQSIMP9SjmhatFbAvxep8xgcwbeAobGTqCgUp+0EdFZR1ktKSND/S+UDU1YSNCFRvlNTJ6YmXUkW36NQME4wHQYDVR0OBBYEFDQxIZoKNniNuW91UMJ1KWEjs045MB8GA1UdIwQYMBaAFDQxIZoKNniNuW91UMJ1KWEjs045MAwGA1UdEwQFMAMBAf8wCgYIKoZIzj0EAwMDaQAwZgIxANbml6sp5A92qQiCM/OtBf+TbXpSpIO83TuNP9V2lsphp0CEX3KwAuqBXB95m9/xWAIxAOXAT2LqieSbUh4fpxcdaeY01RoGtD2AQch1a6BuIugcQqTfqLcXy7D51R70R729sA==";
// an ECC 384 CA-signed cert
//char cert_b64[]="MIICCjCCAZACAQgwCgYIKoZIzj0EAwMwYjELMAkGA1UEBhMCSUUxEDAOBgNVBAgMB0lyZWxhbmQxDzANBgNVBAcMBkR1YmxpbjEhMB8GA1UECgwYSW50ZXJuZXQgV2lkZ2l0cyBQdHkgTHRkMQ0wCwYDVQQDDARtaWtlMB4XDTE1MTEyNjE1NTIxMFoXDTE3MTEyNTE1NTIxMFowgYIxCzAJBgNVBAYTAklFMRAwDgYDVQQIDAdJcmVsYW5kMQ8wDQYDVQQHDAZEdWJsaW4xETAPBgNVBAoMCENlcnRpdm94MQ0wCwYDVQQLDARMYWJzMQ0wCwYDVQQDDARtaWtlMR8wHQYJKoZIhvcNAQkBFhBtc2NvdHRAaW5kaWdvLmllMHYwEAYHKoZIzj0CAQYFK4EEACIDYgAEf2Qm6jH2U+vhAApsMqH9gzGCH8rk+mUwFSD3Uud4NiyPBqrJRC1eetVvr3cYb6ucDTa15km6QKvZZrsRW+Z4ZpryoEE6esmD4XPLrtrOtoxtxFNRhiMmT/M9zcrfMJC5MAoGCCqGSM49BAMDA2gAMGUCMF0x6PAvvnJR3riZdUPC4OWFC2K3eiz3QuLCdFOZVIqX7mkLftdS8BtzusXWMMgFCQIxALJNMKLs39P9wYQHu1C+v9ieltQr20C+WVYxqUvgL/KTdxd9dzc3wseZRDT1CydqOA==";
// an RSA 3072 CA-signed cert
//char cert_b64[]="MIIDFjCCAp4CAQkwCgYIKoZIzj0EAwMwYjELMAkGA1UEBhMCSUUxEDAOBgNVBAgMB0lyZWxhbmQxDzANBgNVBAcMBkR1YmxpbjEhMB8GA1UECgwYSW50ZXJuZXQgV2lkZ2l0cyBQdHkgTHRkMQ0wCwYDVQQDDARtaWtlMB4XDTE1MTEyNjE2MTYwNloXDTE3MTEyNTE2MTYwNlowYzELMAkGA1UEBhMCSUUxEDAOBgNVBAgMB0lyZWxhbmQxDzANBgNVBAcMBkR1YmxpbjERMA8GA1UECgwIQ2VydGl2b3gxDTALBgNVBAsMBGxhYnMxDzANBgNVBAMMBmtlYWxhbjCCAaIwDQYJKoZIhvcNAQEBBQADggGPADCCAYoCggGBAK5QhVjR+UGt3ZWPSGicpviqaOhxXmmvOepdl5Seqr+Iweb3IuEDgtHGwrw/EEgWlKPfS/2LW9ncptdNbVQh7+2rojj7ZtedrAK5p7I9b22f2U3sSHIqjtTT0BjqzL0qEwy/ATqbf93Tcr3yT0Ygh3yzbvn4zodrWQZK8kkN3PQKkiHBCuIxo+8MlTs8d99dl1hbJ84MYZuPmhrkB4oLEAt8+srtL+a4Yd0wPhuCYrLjBnYkD9TlcWLWWh8/iwXiznrY8gQsXSveQNzQjcmHilZrTlTL2dnyI2v7BAXXHSwo6UeES0n064fnYTr3JB0GArMcty6RD3E7xr64HNzzTE2+8cDxufNvU0tq2Z72oZ9cAReHUL5P6mLfORI+AhtCHrXGJch/F07ZX9h8UFpzok8NK5++Q7lHKuezTYRRPlDL5hDB3BUpBwvILdqujcbNil04cuLRBNT/WgqRXEBRjlHLgZaLChFV2VSJ9Z1Uke2lfm5X2O0XPQLhjMSiuvr4HwIDAQABMAoGCCqGSM49BAMDA2YAMGMCLxHSQAYP2EsuIpR4TzDDSIlsw4BBsD7W0ZfH91v9J0j5UWQJD/yNjMtyA2Qlkq/0AjB+SJQbLgycNJH5SnR/X5wx26/62ln9s0swUtlCYVtNzyEQ3YRHSZbmTbh16RUT7Ak=";

#endif

#if CHOICE==NIST521

// ** CA is ECC 521 based - - for use with NIST521 build of library - assumes use of SHA512 in Certs
// ECC 521 Self-Signed CA Cert
char ca_b64[]="MIIC+TCCAlqgAwIBAgIJAKlppiHsRpY8MAoGCCqGSM49BAMEMIGUMQswCQYDVQQGEwJJRTEQMA4GA1UECAwHSXJlbGFuZDEPMA0GA1UEBwwGRHVibGluMSEwHwYDVQQKDBhJbnRlcm5ldCBXaWRnaXRzIFB0eSBMdGQxDTALBgNVBAsMBExhYnMxDzANBgNVBAMMBm1zY290dDEfMB0GCSqGSIb3DQEJARYQbXNjb3R0QGluZGlnby5pZTAeFw0xNTEyMDExMzE5MjZaFw0yMDExMzAxMzE5MjZaMIGUMQswCQYDVQQGEwJJRTEQMA4GA1UECAwHSXJlbGFuZDEPMA0GA1UEBwwGRHVibGluMSEwHwYDVQQKDBhJbnRlcm5ldCBXaWRnaXRzIFB0eSBMdGQxDTALBgNVBAsMBExhYnMxDzANBgNVBAMMBm1zY290dDEfMB0GCSqGSIb3DQEJARYQbXNjb3R0QGluZGlnby5pZTCBmzAQBgcqhkjOPQIBBgUrgQQAIwOBhgAEAKUj6Qa4Vr1vyango8XHlLIIEzY9IVppdpGUrMlNfo0Spu+AXGhnluwJTZXOYLi8jSIPEAL7vuwS5H6uPPIz1QWXALRETVYAQfK0pIfPHq+edTHVTXMcAUpdNla2d4LwYO7HpkSQFHd7aaDN3yVhSL2J0LBLgy0wGkEHuyK1O2r0xNu6o1AwTjAdBgNVHQ4EFgQU966PLshKffU/NRCivMmNq8RiRkAwHwYDVR0jBBgwFoAU966PLshKffU/NRCivMmNq8RiRkAwDAYDVR0TBAUwAwEB/zAKBggqhkjOPQQDBAOBjAAwgYgCQgHkLczeTWXq5BfY0bsTOSNU8bYy39OhiQ8wr5rlXY0zOg0fDyokueL4dhkXp8FjbIyUfQBY5OMxjtcn2p+cXU+6MwJCAci61REgxZvjpf1X8pGeSsOKa7GhfsfVnbQm+LQmjVmhMHbVRkQ4h93CENN4MH/86XNozO9USh+ydTislAcXvCb0";
// an ECC 521 CA-signed cert
char cert_b64[]="MIICZjCCAccCAQMwCgYIKoZIzj0EAwQwgZQxCzAJBgNVBAYTAklFMRAwDgYDVQQIDAdJcmVsYW5kMQ8wDQYDVQQHDAZEdWJsaW4xITAfBgNVBAoMGEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZDENMAsGA1UECwwETGFiczEPMA0GA1UEAwwGbXNjb3R0MR8wHQYJKoZIhvcNAQkBFhBtc2NvdHRAaW5kaWdvLmllMB4XDTE1MTIwMTEzMjkxN1oXDTE3MTEzMDEzMjkxN1owYTELMAkGA1UEBhMCSUUxEDAOBgNVBAgMB0lyZWxhbmQxDzANBgNVBAcMBkR1YmxpbjERMA8GA1UECgwIQ2VydGlWb3gxDTALBgNVBAsMBExhYnMxDTALBgNVBAMMBE1pa2UwgZswEAYHKoZIzj0CAQYFK4EEACMDgYYABAAva/N4kP2LMSGJZ5tvULlfdNx2M/+xYeCrQkuFmY8sG+mdcUAaSx819fztn2jz1nfdTJnuj79AhfUOL8hlTW14BwErp3DnqWa7Y/rpSJP+AsnJ2bZg4yGUDfVy/Q0AQychSzJm2oGRfdliyBIc+2SoQJ/Rf0ZVKVJ5FfRbWUUiKqYUqjAKBggqhkjOPQQDBAOBjAAwgYgCQgFE1Y7d9aBdxpZqROtkdVNG8XBCTSlMX0fISWkSM8ZEiQfYf7YgXzLjk8wHnv04Mv6kmAuV0V1AHs2M0/753CYEfAJCAPZo801McsGe+3jYALrFFw9Wj7KQC/sFEJ7/I+PYyJtrlfTTqmV0IFKdJzjEsk7ic+Gd4Nbs6kIe1GyYbrcyC4wT";

#endif

char io[5000];
octet IO= {0,sizeof(io),io};

#define MAXMODBYTES 72
#define MAXFFLEN 16

char sig[MAXMODBYTES*MAXFFLEN];
octet SIG= {0,sizeof(sig),sig};

char r[MAXMODBYTES];
octet R= {0,sizeof(r),r};

char s[MAXMODBYTES];
octet S= {0,sizeof(s),s};

char cakey[MAXMODBYTES*MAXFFLEN];
octet CAKEY= {0,sizeof(cakey),cakey};

char certkey[MAXMODBYTES*MAXFFLEN];
octet CERTKEY= {0,sizeof(certkey),certkey};

char h[5000];
octet H= {0,sizeof(h),h};

char hh[5000];
octet HH= {0,sizeof(hh),hh};

char hp[RFS];
octet HP= {0,sizeof(hp),hp};

int main()
{
    int res,len,sha;
    int c,ic;
    rsa_public_key PK;
    pktype st,ca,pt;

    printf("First check signature on self-signed cert and extract CA public key\n");
    OCT_frombase64(&IO,ca_b64);
    printf("CA Self-Signed Cert= \n");
    OCT_output(&IO);
    printf("\n");

    st=X509_extract_cert_sig(&IO,&SIG); // returns signature type

    if (st.type==0)
    {
        printf("Unable to extract cert signature\n");
        return 0;
    }

    if (st.type==ECC)
    {
        OCT_chop(&SIG,&S,SIG.len/2);
        OCT_copy(&R,&SIG);
        printf("ECC SIG= \n");
        OCT_output(&R);
        OCT_output(&S);
        printf("\n");
    }

    if (st.type==RSA)
    {
        printf("RSA SIG= \n");
        OCT_output(&SIG);
        printf("\n");
    }

    if (st.hash==H256) printf("Hashed with SHA256\n");
    if (st.hash==H384) printf("Hashed with SHA384\n");
    if (st.hash==H512) printf("Hashed with SHA512\n");

// Extract Cert from signed Cert

    c=X509_extract_cert(&IO,&H);

    printf("\nCert= \n");
    OCT_output(&H);
    printf("\n");

// show some details
    printf("Issuer Details\n");
    ic=X509_find_issuer(&H);
    c=X509_find_entity_property(&H,&ON,ic,&len);
    print_out("owner=",&H,c,len);
    c=X509_find_entity_property(&H,&CN,ic,&len);
    print_out("country=",&H,c,len);
    c=X509_find_entity_property(&H,&EN,ic,&len);
    print_out("email=",&H,c,len);
    printf("\n");

    ca=X509_extract_public_key(&H,&CAKEY);

    if (ca.type==0)
    {
        printf("Not supported by library\n");
        return 0;
    }
    if (ca.type!=st.type)
    {
        printf("Not self-signed\n");
    }

    if (ca.type==ECC)
    {
        printf("EXTRACTED ECC PUBLIC KEY= \n");
        OCT_output(&CAKEY);
    }
    if (ca.type==RSA)
    {
        printf("EXTRACTED RSA PUBLIC KEY= \n");
        OCT_output(&CAKEY);
    }
    printf("\n");

// Cert is self-signed - so check signature

    printf("Checking Self-Signed Signature\n");
    if (ca.type==ECC)
    {
        if (ca.curve!=CHOICE)
        {
            printf("Curve is not supported\n");
            return 0;
        }
        res=ECP_PUBLIC_KEY_VALIDATE(1,&CAKEY);
        if (res!=0)
        {
            printf("ECP Public Key is invalid!\n");
            return 0;
        }
        else printf("ECP Public Key is Valid\n");

        sha=0;

        if (st.hash==H256) sha=SHA256;
        if (st.hash==H384) sha=SHA384;
        if (st.hash==H512) sha=SHA512;
        if (st.hash==0)
        {
            printf("Hash Function not supported\n");
            return 0;
        }

        if (ECPVP_DSA(sha,&CAKEY,&H,&R,&S)!=0)
        {
            printf("***ECDSA Verification Failed\n");
            return 0;
        }
        else
            printf("ECDSA Signature/Verification succeeded \n");
    }

    if (ca.type==RSA)
    {
        PK.e=65537; // assuming this!
        FF_fromOctet(PK.n,&CAKEY,FFLEN);

        sha=0;

        if (st.hash==H256) sha=SHA256;
        if (st.hash==H384) sha=SHA384;
        if (st.hash==H512) sha=SHA512;
        if (st.hash==0)
        {
            printf("Hash Function not supported\n");
            return 0;
        }
        PKCS15(sha,&H,&HP);

        RSA_ENCRYPT(&PK,&SIG,&HH);

        if (OCT_comp(&HP,&HH))
            printf("RSA Signature/Verification succeeded \n");
        else
        {
            printf("***RSA Verification Failed\n");
            return 0;
        }
    }

    printf("\nNext check CA signature on cert, and extract public key\n");

    OCT_frombase64(&IO,cert_b64);
    printf("Example Cert= \n");
    OCT_output(&IO);
    printf("\n");

    st=X509_extract_cert_sig(&IO,&SIG);

    if (st.type==0)
    {
        printf("Unable to check cert signature\n");
        return 0;
    }

    if (st.type==ECC)
    {
        OCT_chop(&SIG,&S,SIG.len/2);
        OCT_copy(&R,&SIG);
        printf("SIG= \n");
        OCT_output(&R);

        OCT_output(&S);

        printf("\n");
    }

    if (st.type==RSA)
    {
        printf("SIG= \n");
        OCT_output(&SIG);
        printf("\n");
    }

    c=X509_extract_cert(&IO,&H);

    printf("Cert= \n");
    OCT_output(&H);
    printf("\n");

    printf("Subject Details\n");
    ic=X509_find_subject(&H);
    c=X509_find_entity_property(&H,&ON,ic,&len);
    print_out("owner=",&H,c,len);
    c=X509_find_entity_property(&H,&CN,ic,&len);
    print_out("country=",&H,c,len);
    c=X509_find_entity_property(&H,&EN,ic,&len);
    print_out("email=",&H,c,len);
    printf("\n");

    ic=X509_find_validity(&H);
    c=X509_find_start_date(&H,ic);
    print_date("start date= ",&H,c);
    c=X509_find_expiry_date(&H,ic);
    print_date("expiry date=",&H,c);
    printf("\n");

    pt=X509_extract_public_key(&H,&CERTKEY);

    if (pt.type==0)
    {
        printf("Not supported by library\n");
        return 0;
    }

    if (pt.type==ECC)
    {
        printf("EXTRACTED ECC PUBLIC KEY= \n");
        OCT_output(&CERTKEY);
    }
    if (pt.type==RSA)
    {
        printf("EXTRACTED RSA PUBLIC KEY= \n");
        OCT_output(&CERTKEY);
    }

    printf("\n");

    /* Check CA signature */

    if (ca.type==ECC)
    {
        printf("Checking CA's ECC Signature on Cert\n");
        res=ECP_PUBLIC_KEY_VALIDATE(1,&CAKEY);
        if (res!=0)
            printf("ECP Public Key is invalid!\n");
        else printf("ECP Public Key is Valid\n");

        sha=0;

        if (st.hash==H256) sha=SHA256;
        if (st.hash==H384) sha=SHA384;
        if (st.hash==H512) sha=SHA512;
        if (st.hash==0)
        {
            printf("Hash Function not supported\n");
            return 0;
        }

        if (ECPVP_DSA(sha,&CAKEY,&H,&R,&S)!=0)
            printf("***ECDSA Verification Failed\n");
        else
            printf("ECDSA Signature/Verification succeeded \n");
    }

    if (ca.type==RSA)
    {
        printf("Checking CA's RSA Signature on Cert\n");
        PK.e=65537; // assuming this!
        FF_fromOctet(PK.n,&CAKEY,FFLEN);

        sha=0;

        if (st.hash==H256) sha=SHA256;
        if (st.hash==H384) sha=SHA384;
        if (st.hash==H512) sha=SHA512;
        if (st.hash==0)
        {
            printf("Hash Function not supported\n");
            return 0;
        }
        PKCS15(sha,&H,&HP);

        RSA_ENCRYPT(&PK,&SIG,&HH);

        if (OCT_comp(&HP,&HH))
            printf("RSA Signature/Verification succeeded \n");
        else
            printf("***RSA Verification Failed\n");

    }

    return 0;
}


