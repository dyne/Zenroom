/*
 * Copyright (c) 2012-2020 MIRACL UK Ltd.
 *
 * This file is part of MIRACL Core
 * (see https://github.com/miracl/core).
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/* CORE X.509 Functions */

// To run test program
// gcc -std=c99 x509.c core.a -o x509

#include <stdio.h>
#include <amcl.h>  // for octet support only
#include <x509.h>

// assumes library support for all of these
// #include "eddsa_Ed448.h"
// #include "eddsa_Ed25519.h"
// #include "ecdh_NIST256.h"
// #include "ecdh_NIST521.h"
#include "rsa_4096.h"
#include "rsa_2048.h"

/* This simple driver program is hard-wired to support just one elliptic curve and one
   RSA bit length. To change replace the text string NIST256 in the main program to
   another curve and 2048 to some other value, where the curve and the RSA bit length
   are suppported by the library. Of course a more elaborate program could support
   muliple curves simultaneously */

#define CHOICE USE_ED448

/* test driver program */
// Sample Certs. Uncomment one CA cert and one example cert. Note that CORE library must be built to support given curve.
// Sample Certs all created using OpenSSL - see http://blog.didierstevens.com/2008/12/30/howto-make-your-own-cert-with-openssl/
// Note - SSL currently only supports NIST curves. Howevever version 1.1.0 of OpenSSL now supports C25519

#if CHOICE==USE_NIST256

// ** CA is RSA 2048-bit based - for use with NIST256 build of library - assumes use of SHA256 in Certs
// RSA 2048 Self-Signed CA cert
char ca_b64[] = "MIIDuzCCAqOgAwIBAgIJAP44jcM1MOROMA0GCSqGSIb3DQEBCwUAMHQxCzAJBgNVBAYTAklFMRAwDgYDVQQIDAdJcmVsYW5kMQ8wDQYDVQQHDAZEdWJsaW4xITAfBgNVBAoMGEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZDEfMB0GCSqGSIb3DQEJARYQbXNjb3R0QGluZGlnby5pZTAeFw0xNTExMjYwOTUwMzlaFw0yMDExMjUwOTUwMzlaMHQxCzAJBgNVBAYTAklFMRAwDgYDVQQIDAdJcmVsYW5kMQ8wDQYDVQQHDAZEdWJsaW4xITAfBgNVBAoMGEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZDEfMB0GCSqGSIb3DQEJARYQbXNjb3R0QGluZGlnby5pZTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBANUs7/nri9J8zw8rW8JVszXP0ZqeLoQJaq2X28ebm8x5VT3okr9rnBjFjpx0YKQCAFQf8iSOOYuNpDvtZ/YpsjPbk2rg5sLY9G0eUMqrTuZ7moPSxnrXS5evizjD9Z9HqaqeNEYD3sPouPg+lhU1oAUQjUTJVFhEr1x0EnSEYbbrWtY9ZDSuZv+d4NIeqqPOYFd1yZc+LYZyQbAAQqwRLNPZH/rnIykLa6I7w7mGT7H6SBz2O09BtgpTHhalL40ecXa4ZOEze0xwzlc+mEFIrnmdadg3vQrJt42RVbo3LN6RfDIqUZOMOtQW/53pUR1lIpCwVWJTiOpmSEIEqhhjFq0CAwEAAaNQME4wHQYDVR0OBBYEFJrz6LHeT6FcjRahpUC3hAMxKRTCMB8GA1UdIwQYMBaAFJrz6LHeT6FcjRahpUC3hAMxKRTCMAwGA1UdEwQFMAMBAf8wDQYJKoZIhvcNAQELBQADggEBADqkqCYVa3X8XO9Ufu6XIUoZafFPRjSeJXvEIWqlbm7ixJZ2FPOvf2eMc5RCZYigNKhsxru5Ojw0lPcpa8DDmEsdZDf7p0vlmf7T7xH9gtoInh4DzgI8HRHFc8R/z2/jLX7nlLoopKX5yp7F1gRACg0pd4tGpQ6EnBNcYZZghFH9UIRDmx+vDlwDCu8vyRPt35orrEiI4XGq/QkvxxAb5YWxQ4i06064ULfyCI7suu3KoobdM1aAaA8zhpOOBXKbq+Wi9IGFe/wiEMHLmfHdt9CBTjIWb//IHji4RT05kCmTVrx97pb7EHafuL3L10mM5cpTyBWKnb4kMFtx9yw+S2U=";
// an RSA 2048 CA-signed cert
char cert_b64[]="MIIDcjCCAloCAQEwDQYJKoZIhvcNAQELBQAwdDELMAkGA1UEBhMCSUUxEDAOBgNVBAgMB0lyZWxhbmQxDzANBgNVBAcMBkR1YmxpbjEhMB8GA1UECgwYSW50ZXJuZXQgV2lkZ2l0cyBQdHkgTHRkMR8wHQYJKoZIhvcNAQkBFhBtc2NvdHRAaW5kaWdvLmllMB4XDTE1MTEyNjEwMzQzMFoXDTE3MTEyNTEwMzQzMFowgYkxCzAJBgNVBAYTAklFMRAwDgYDVQQIDAdJcmVsYW5kMQ8wDQYDVQQHDAZEdWJsaW4xETAPBgNVBAoMCENlcnRpVm94MQ0wCwYDVQQLDARMYWJzMQ0wCwYDVQQDDARNSUtFMSYwJAYJKoZIhvcNAQkBFhdtaWtlLnNjb3R0QGNlcnRpdm94LmNvbTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMIoxaQHFQzfyNChrw+3i7FjRFMHZ4zspkjkAcJW21LdBCqrxU+sdjyBoSFlrlafQOHshbrEP93AKX1bfaYbuV4fzq7OlRaLxaK+b+xrOJdewMI2WZ5OwEzj3onZATISogIoB6dTdzJ41NuxuMqQ/DqOnVrRA0SoIespbQhB8FGHBLw0hJATBzUk+bqOIt0HmnMp2EbYgtuG4lYINU/lD3Qt16SunUukWRLtxqJkioie+dkhP2zm+bOlSVmeQb4Wp8AI14OKkTfkdYC8qCxb5eabg90Q33rQUhNwRQHhHwopZwD/BgodasoSrPfwUlj0awh6y87eMGcik5Q/mjkCk5MCAwEAATANBgkqhkiG9w0BAQsFAAOCAQEAFrd7R/67ClkbLhpiX++6QTOa47siUAB9v+Qil9hZfhPNeeM589ixYkD4zH5pOK2B0ea+CXEKkanQ6lXx9KV86yS7fq6Yww7wO0diecusHd0+P82i46Tq0nm8nlsnAuhYoFRUGa2m2DkB1HSsB0ts8DjzFLySonFjSSLHDU0ox9/uFbJMzipy3ijAA4XM0N4jRrUfrmxpA7DOOsbEbGkvvB7VK9+s9PHE/4dJTwhSteplUnhxVFkkDo/JwaLx4/IEQRlCF3KEQ5s3AwRHnbrIjOY2yONxHBtJEp7QN5aOHruwvMNRNheCBPiQJyLitUsFGr4voANmobkrFgYtu0tRMQ==";
// an ECC 256 CA-signed cert
// char cert_b64[] = "MIICojCCAYoCAQMwDQYJKoZIhvcNAQELBQAwdDELMAkGA1UEBhMCSUUxEDAOBgNVBAgMB0lyZWxhbmQxDzANBgNVBAcMBkR1YmxpbjEhMB8GA1UECgwYSW50ZXJuZXQgV2lkZ2l0cyBQdHkgTHRkMR8wHQYJKoZIhvcNAQkBFhBtc2NvdHRAaW5kaWdvLmllMB4XDTE1MTEyNjEzNDcyOVoXDTE3MTEyNTEzNDcyOVowgYQxCzAJBgNVBAYTAklFMRAwDgYDVQQIDAdJcmVsYW5kMQ8wDQYDVQQHDAZEdWJsaW4xETAPBgNVBAoMCENlcnRpdm94MQ0wCwYDVQQLDARMYWJzMQ8wDQYDVQQDDAZtc2NvdHQxHzAdBgkqhkiG9w0BCQEWEG1zY290dEBpbmRpZ28uaWUwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAATO2iZiQZsXxzwBKnufKfZcsctNXZ4PmfJm638PmX9DQ3Xdb+nD5VxiOakNcB9xf5im8CriiOF5Z/7yPGyzUMbdMA0GCSqGSIb3DQEBCwUAA4IBAQAK5fMgGCCiPts8hMUZvYDpu8hd7qtPKPBc10QUccHb7PGrhqf/Ex2Gpj1aaURmx7SGZG0HX97LtkdW8KQpEoyaa60r7cjVA589TznxXKSGg5ggVoFJNpuZUm7VcolLjwIgTxtGbPzrvVMiZ4cl4PwFePXVKTl4f8XkOFX5gLmVSuCf729lEBmpx3IzqGmTjmnBixaApUElOKVeL7hiUKP3TqMUxZN+QNJBq4Mh9K9h4Sks2oneLwBwhMqQvpmcOb/7SucJn5N0IgJoGaMbfX0oCJJID1NSbagUSbFD1XciR2Ng9VtvnRP+htmEQ7jtww8phFdrWt5M5zPGOHUppqDx";

// ** CA is ECC 256 based  - for use with NIST256 build of library
// ECC 256 Self-Signed CA cert
//char ca_b64[]="MIIB7TCCAZOgAwIBAgIJANp4nGS/VYj2MAoGCCqGSM49BAMCMFMxCzAJBgNVBAYTAklFMRAwDgYDVQQIDAdJcmVsYW5kMQ8wDQYDVQQHDAZEdWJsaW4xITAfBgNVBAoMGEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZDAeFw0xNTExMjYxMzI0MTBaFw0yMDExMjUxMzI0MTBaMFMxCzAJBgNVBAYTAklFMRAwDgYDVQQIDAdJcmVsYW5kMQ8wDQYDVQQHDAZEdWJsaW4xITAfBgNVBAoMGEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZDBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABPb6IjYNKyfbEtL1aafzW1jrn6ALn3PnGm7AyX+pcvwG0GKmb3Z/uHzhT4GysNE0/GB1n4Y/mrORQIm2X98rRs6jUDBOMB0GA1UdDgQWBBSfXUNkgJVklIhuXq4DCnVYhsdzwDAfBgNVHSMEGDAWgBSfXUNkgJVklIhuXq4DCnVYhsdzwDAMBgNVHRMEBTADAQH/MAoGCCqGSM49BAMCA0gAMEUCIQDrZJ1tshwTl/jabU2i49EOgbWe0ZgE3QZywJclf5IVwwIgVmz79AAf7e098lyrOKYAqbwjHVyMZGfmkNNGIuIhp/Q=";
// an ECC 256 CA-signed cert
//char cert_b64[]="MIIBvjCCAWQCAQEwCgYIKoZIzj0EAwIwUzELMAkGA1UEBhMCSUUxEDAOBgNVBAgMB0lyZWxhbmQxDzANBgNVBAcMBkR1YmxpbjEhMB8GA1UECgwYSW50ZXJuZXQgV2lkZ2l0cyBQdHkgTHRkMB4XDTE1MTEyNjEzMjc1N1oXDTE3MTEyNTEzMjc1N1owgYIxCzAJBgNVBAYTAklFMRAwDgYDVQQIDAdJcmVsYW5kMQ8wDQYDVQQHDAZEdWJsaW4xETAPBgNVBAoMCENlcnRpdm94MQ0wCwYDVQQLDARMYWJzMQ0wCwYDVQQDDARtaWtlMR8wHQYJKoZIhvcNAQkBFhBtc2NvdHRAaW5kaWdvLmllMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEY42H52TfWMLueKB1o2Sq8uKaKErbHJ2GRAxrnJdNxex0hxZF5FUx7664BbPUolKhpvKTnJxDq5/gMqXzpKgR6DAKBggqhkjOPQQDAgNIADBFAiEA0ew08Xg32g7BwheslVKwXo9XRRx4kygYha1+cn0tvaUCIEKCEwnosZlAckjcZt8aHN5zslE9K9Y7XxTErTstthKc";
// an RSA 2048 CA-signed cert
// char cert_b64[]="MIICiDCCAi4CAQIwCgYIKoZIzj0EAwIwUzELMAkGA1UEBhMCSUUxEDAOBgNVBAgMB0lyZWxhbmQxDzANBgNVBAcMBkR1YmxpbjEhMB8GA1UECgwYSW50ZXJuZXQgV2lkZ2l0cyBQdHkgTHRkMB4XDTE1MTEyNjEzMzcwNVoXDTE3MTEyNTEzMzcwNVowgYExCzAJBgNVBAYTAklFMQ8wDQYDVQQIDAZJZWxhbmQxDzANBgNVBAcMBkR1YmxpbjERMA8GA1UECgwIQ2VydGl2b3gxDTALBgNVBAsMBExhYnMxDTALBgNVBAMMBE1pa2UxHzAdBgkqhkiG9w0BCQEWEG1zY290dEBpbmRpZ28uaWUwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCjPBVwmPg8Gwx0+8xekmomptA0BDwS7NUfBetqDqNMNyji0bSe8LAfpciU7NW/HWfUE1lndCqSDDwnMJmwC5e3GAl/Bus+a+z8ruEhWGbn95xrHXFkOawbRlXuS7UcEQCvPr8KQHhNsg4cyV7Hn527CPUl27n+WN8/pANo01cTN/dQaK87naU0Mid09vktlMKSN0zyJOnc5CsaTLs+vCRKJ9sUL3d4IQIA2y7gvrTe+iY/QI26nqhGpNWYyFkAdy9PdHUEnDI6JsfF7jFh37yG7XEgDDA3asp/oi1T1+ZoASj2boL++opdqCzDndeWwzDWAWuvJ9wULd80ti6x737ZAgMBAAEwCgYIKoZIzj0EAwIDSAAwRQIgCDwgl98+9moBo+etaLt8MvB/z5Ti6i9neRTZkvoFl7YCIQDq//M3OB757fepErRzIQo3aFAFYjOooi6WdSqP3XqGIg==";

#endif

#if CHOICE==USE_ED25519

// **CA is EDDSA Ed25519 based. Self-signed cert
char ca_b64[]= "MIIBRTCB+KADAgECAhNBrGyCRdfc0WyPpPd+LB8LEiK4MAUGAytlcDAZMRcwFQYDVQQDDA5NaWtlJ3Mgcm9vdCBDQTAeFw0yMzA1MDExNjAwMDlaFw0yNDA0MzAxNjAwMDlaMBkxFzAVBgNVBAMMDk1pa2UncyByb290IENBMCowBQYDK2VwAyEAh8YXRWdICdF8CcR1P0RCO4xD+s5i8Pzpq8KHid/TQaajUzBRMB0GA1UdDgQWBBQAS56sNYWyao4k6DS/M81i+wqjIzAfBgNVHSMEGDAWgBQAS56sNYWyao4k6DS/M81i+wqjIzAPBgNVHRMBAf8EBTADAQH/MAUGAytlcANBAJWIicxVB6ynhjjkJgNtcL/kmixU7l/V1j/N0AtenDgT+yrMhDW9n9JC+Ze5qpX3Eu3VkdkpN3G9anmBXp3LtAk=";
// EDDSA Ed25519 CA-signed Cert
char cert_b64[]="MIHdMIGQAgEBMAUGAytlcDAZMRcwFQYDVQQDDA5NaWtlJ3Mgcm9vdCBDQTAeFw0yMzA1MDExNjA1NDhaFw0yNDA0MzAxNjA1NDhaMB0xGzAZBgNVBAMMEk1pa2UncyBzZXJ2ZXIgY2VydDAqMAUGAytlcAMhANvhwg8UhnGMGt0bKoGt5IHkvHwyEwWj4GkLQ7XIqJeVMAUGAytlcANBAESWzTJbz/YVwLFrDKVqYxHc86YGjPa8lekAC8UciIKu9d1Xoko3ssfhNiXkYkl3M0yEnIkD2F2DfGKbt8LSmQE=";

#endif

#if CHOICE==USE_ED448

// **CA is EDDSA Ed448 based. Self-signed cert
char ca_b64[]= "MIIBkjCCARKgAwIBAgIUWnfFe8sR7CGIz3eN1CfyHdTz14kwBQYDK2VxMBkxFzAVBgNVBAMMDk1pa2UncyByb290IENBMB4XDTIzMDUwMTE2NDQxMloXDTI0MDQzMDE2NDQxMlowGTEXMBUGA1UEAwwOTWlrZSdzIHJvb3QgQ0EwQzAFBgMrZXEDOgACd4YB/lGYUck4KxQMJ+lshkHnBuigmwPALPQGARv26SK/EOi0DIMMpyp3oG+pnPpnqbqtDtesCYCjUzBRMB0GA1UdDgQWBBRygDXbx5h57oo1D91LitQV2PE2dzAfBgNVHSMEGDAWgBRygDXbx5h57oo1D91LitQV2PE2dzAPBgNVHRMBAf8EBTADAQH/MAUGAytlcQNzAI17NGvKrGAH5hKLUHC1+Qv5RvT4IKlWg5GnRGTccc5tCrimveoMbu2KTlNXaOHS8y/sZT1qddukAFLzR/1ehZqOnYLM7dwlgYdksAx0olo5+/MYfj3hw5noh1pMObnJREfTPTSg1gqFI+gObB1UoSsBAA=="; 
// EDDSA Ed448 CA-signed Cert
char cert_b64[]="MIIBIzCBpAIBATAFBgMrZXEwGTEXMBUGA1UEAwwOTWlrZSdzIHJvb3QgQ0EwHhcNMjMwNTAxMTY0NjQzWhcNMjQwNDMwMTY0NjQzWjAYMRYwFAYDVQQDDA1NaWtlJ3Mgc2VydmVyMEMwBQYDK2VxAzoAgYh3CQP+EgId5/TZjAsuxh7Y9nPYtN5CYeN8vLjPuRqQncja3MyhRJaOrUEKSnBK+zYbkdXMQQwAMAUGAytlcQNzAPcm8DVSRZA1r0QqsSsHv6xBy1ASaoz4RFyelFMUD4f6ERMaxTzs0LKQHtcx5G9vqOxvQyCgkEu2AOcUQLtEXcoOSLH8fy0+5yEbbs6uPA1hi/oGpy580SR/5K5odY35fe1kwhz9YUvT4suTRHocnpcsAA==";
#endif


char io[5000];
octet IO = {0, sizeof(io), io};

#define MAXMODBYTES 72
#define MAXFFLEN 16

char sig[MAXMODBYTES * MAXFFLEN];
octet SIG = {0, sizeof(sig), sig};

char r[MAXMODBYTES];
octet R = {0, sizeof(r), r};

char s[MAXMODBYTES];
octet S = {0, sizeof(s), s};

char cakey[MAXMODBYTES * MAXFFLEN];
octet CAKEY = {0, sizeof(cakey), cakey};

char certkey[MAXMODBYTES * MAXFFLEN];
octet CERTKEY = {0, sizeof(certkey), certkey};

char h[5000];
octet H = {0, sizeof(h), h};

char hh[5000];
octet HH = {0, sizeof(hh), hh};

char hp[RFS_2048];
octet HP = {0, sizeof(hp), hp};

void print_out(char *des, octet *c, int index, int len)
{
    int i;
    printf("%s [", des);
    for (i = 0; i < len; i++)
        printf("%c", c->val[index + i]);
    printf("]\n");
}

void print_date(char *des, octet *c, int index)
{
    int i = index;
    printf("%s [", des);
    if (i == 0) printf("]\n");
    else printf("20%c%c-%c%c-%c%c %c%c:%c%c:%c%c]\n", c->val[i], c->val[i + 1], c->val[i + 2], c->val[i + 3], c->val[i + 4], c->val[i + 5], c->val[i + 6], c->val[i + 7], c->val[i + 8], c->val[i + 9], c->val[i + 10], c->val[i + 11]);
}

int main()
{
    int res, len, sha;
    int c, ic;
    rsa_public_key_2048 PK;
    pktype st, ca, pt;

    printf("First check signature on self-signed cert and extract CA public key\n");
    OCT_frombase64(&IO, ca_b64);
    printf("CA Self-Signed Cert= \n");
    OCT_output(&IO);
    printf("\n");

    st = X509_extract_cert_sig(&IO, &SIG); // returns signature type

    if (st.type == 0)
    {
        printf("Unable to extract cert signature\n");
        return 0;
    }

    if (st.type == X509_ECC)
    {
        OCT_chop(&SIG, &S, SIG.len / 2);
        OCT_copy(&R, &SIG);
        printf("ECC SIG= \n");
        OCT_output(&R);
        OCT_output(&S);
        printf("\n");
    }

    if (st.type == X509_ECD)
    {
        printf("EDDSA SIG= \n");
        OCT_output(&SIG);
        printf("\n");
    }

    if (st.type == X509_RSA)
    {
        printf("RSA SIG= \n");
        OCT_output(&SIG);
        printf("\n");
    }

    if (st.hash == X509_H256) printf("Hashed with SHA256\n");
    if (st.hash == X509_H384) printf("Hashed with SHA384\n");
    if (st.hash == X509_H512) printf("Hashed with SHA512\n");

// Extract Cert from signed Cert

    c = X509_extract_cert(&IO, &H);

    printf("\nCert= \n");
    OCT_output(&H);
    printf("\n");

// show some details
    printf("Issuer Details\n");
    ic = X509_find_issuer(&H,&len);
    c = X509_find_entity_property(&H, &X509_ON, ic, &len);
    print_out("owner=", &H, c, len);
    c = X509_find_entity_property(&H, &X509_CN, ic, &len);
    print_out("country=", &H, c, len);
    c = X509_find_entity_property(&H, &X509_EN, ic, &len);
    print_out("email=", &H, c, len);
    c = X509_find_entity_property(&H, &X509_MN, ic, &len);
    print_out((char *)"Common Name=", &H, c, len);
    printf("\n");

    ca = X509_extract_public_key(&H, &CAKEY);

    if (ca.type == 0)
    {
        printf("Not supported by library\n");
        return 0;
    }
    if (ca.type != st.type)
    {
        printf("Not self-signed\n");
    }

    if (ca.type == X509_ECC)
    {
        printf("EXTRACTED ECC PUBLIC KEY= \n");
        OCT_output(&CAKEY);
    }
    if (ca.type == X509_RSA)
    {
        printf("EXTRACTED RSA PUBLIC KEY= \n");
        OCT_output(&CAKEY);
    }
    printf("\n");

// Cert is self-signed - so check signature

    printf("Checking Self-Signed Signature\n");
    if (ca.type == X509_ECC)
    {
        if (ca.curve != CHOICE)
        {
            printf("Curve is not supported\n");
            return 0;
        }
        // res = ECP_NIST256_PUBLIC_KEY_VALIDATE(&CAKEY);
        // if (res != 0)
        // {
        //     printf("ECP Public Key is invalid!\n");
        //     return 0;
        // }
        // else printf("ECP Public Key is Valid\n");

        sha = 0;

        if (st.hash == X509_H256) sha = SHA256;
        if (st.hash == X509_H384) sha = SHA384;
        if (st.hash == X509_H512) sha = SHA512;
        if (sha == 0)
        {
            printf("Hash Function not supported\n");
            return 0;
        }

        // if (ECP_NIST256_VP_DSA(sha, &CAKEY, &H, &R, &S) != 0)
        // {
        //     printf("***ECDSA Verification Failed\n");
        //     return 0;
        // }
        // else
        //     printf("ECDSA Signature/Verification succeeded \n");
    }

    if (ca.type == X509_ECD)
    {
        if (ca.curve != CHOICE)
        {
            printf("Curve is not supported %d\n",ca.curve);
            return 0;
        }
        // if (ca.curve == USE_ED25519)
        // {
        //     if (!EDDSA_Ed25519_VERIFY(false,&CAKEY,NULL,&H,&SIG))
        //     {
        //         printf("***EDDSA Verification Failed\n");
        //         return 0;
        //     }
        //     else
        //         printf("EDDSA Signature/Verification succeeded \n");
        // }
        // if (ca.curve == USE_ED448)
        // {
        //     if (!EDDSA_Ed448_VERIFY(false,&CAKEY,NULL,&H,&SIG))
        //     {
        //         printf("***EDDSA Verification Failed %d\n",SIG.len);
        //         return 0;
        //     }
        //     else
        //         printf("EDDSA Signature/Verification succeeded \n");
        // }
    }

    if (ca.type == X509_RSA)
    {
        if (ca.curve != 2048)
        {
            printf("RSA bit size is not supported\n");
            return 0;
        }
        PK.e = 65537; // assuming this!
        RSA_2048_fromOctet(PK.n, &CAKEY);

        sha = 0;

        if (st.hash == X509_H256) sha = SHA256;
        if (st.hash == X509_H384) sha = SHA384;
        if (st.hash == X509_H512) sha = SHA512;
        if (sha == 0)
        {
            printf("Hash Function not supported\n");
            return 0;
        }
        PKCS15(sha, &H, &HP);

        RSA_2048_ENCRYPT(&PK, &SIG, &HH);

        if (OCT_comp(&HP, &HH))
            printf("RSA Signature/Verification succeeded \n");
        else
        {
            printf("***RSA Verification Failed\n");
            return 0;
        }
    }

    printf("\nNext check CA signature on cert, and extract public key\n");

    OCT_frombase64(&IO, cert_b64);
    printf("Example Cert= \n");
    OCT_output(&IO);
    printf("\n");

    st = X509_extract_cert_sig(&IO, &SIG);

    if (st.type == 0)
    {
        printf("Unable to check cert signature\n");
        return 0;
    }

    if (st.type == X509_ECC)
    {
        OCT_chop(&SIG, &S, SIG.len / 2);
        OCT_copy(&R, &SIG);
        printf("SIG= \n");
        OCT_output(&R);

        OCT_output(&S);

        printf("\n");
    }

    if (st.type == X509_ECD)
    {
        printf("SIG= \n");
        OCT_output(&SIG);
        printf("\n");
    }

    if (st.type == X509_RSA)
    {
        printf("SIG= \n");
        OCT_output(&SIG);
        printf("\n");
    }

    c = X509_extract_cert(&IO, &H);

    printf("Cert= \n");
    OCT_output(&H);
    printf("\n");

    printf("Subject Details\n");
    ic = X509_find_subject(&H,&len);
    c = X509_find_entity_property(&H, &X509_ON, ic, &len);
    print_out("owner=", &H, c, len);
    c = X509_find_entity_property(&H, &X509_CN, ic, &len);
    print_out("country=", &H, c, len);
    c = X509_find_entity_property(&H, &X509_EN, ic, &len);
    print_out("email=", &H, c, len);
    c = X509_find_entity_property(&H, &X509_MN, ic, &len);
    print_out((char *)"Common Name=", &H, c, len);
    printf("\n");

    ic = X509_find_validity(&H);
    c = X509_find_start_date(&H, ic);
    print_date("start date= ", &H, c);
    c = X509_find_expiry_date(&H, ic);
    print_date("expiry date=", &H, c);
    printf("\n");

    pt = X509_extract_public_key(&H, &CERTKEY);

    if (pt.type == 0)
    {
        printf("Not supported by library\n");
        return 0;
    }

    if (pt.type == X509_ECC)
    {
        printf("EXTRACTED ECDSA PUBLIC KEY= \n");
        OCT_output(&CERTKEY);
    }
    if (pt.type == X509_ECD)
    {
        printf("EXTRACTED EDDSA PUBLIC KEY= \n");
        OCT_output(&CERTKEY);
    }
    if (pt.type == X509_RSA)
    {
        printf("EXTRACTED RSA PUBLIC KEY= \n");
        OCT_output(&CERTKEY);
    }

    printf("\n");

    /* Check CA signature */

    // if (ca.type == X509_ECC)
    // {
    //     // printf("Checking CA's ECC Signature on Cert\n");
    //     // res = ECP_NIST256_PUBLIC_KEY_VALIDATE(&CAKEY);
    //     // if (res != 0)
    //     //     printf("ECP Public Key is invalid!\n");
    //     // else printf("ECP Public Key is Valid\n");

    //     sha = 0;

    //     if (st.hash == X509_H256) sha = SHA256;
    //     if (st.hash == X509_H384) sha = SHA384;
    //     if (st.hash == X509_H512) sha = SHA512;
    //     if (sha == 0)
    //     {
    //         printf("Hash Function not supported\n");
    //         return 0;
    //     }

    //     if (ECP_NIST256_VP_DSA(sha, &CAKEY, &H, &R, &S) != 0)
    //         printf("***ECDSA Verification Failed\n");
    //     else
    //         printf("ECDSA Signature/Verification succeeded \n");
    // }

    // if (ca.type == X509_ECD)
    // {
    //     printf("Checking CA's EDDSA Signature on Cert\n");
    //     if (ca.curve == USE_ED25519)
    //     {
    //         if (!EDDSA_Ed25519_VERIFY(false,&CAKEY,NULL,&H,&SIG))
    //         {
    //             printf("***EDDSA Verification Failed\n");
    //             return 0;
    //         }
    //         else
    //             printf("EDDSA Signature/Verification succeeded \n");
    //     }
    //     if (ca.curve == USE_ED448)
    //     {
    //         if (!EDDSA_Ed448_VERIFY(false,&CAKEY,NULL,&H,&SIG))
    //         {
    //             printf("***EDDSA Verification Failed\n");
    //             return 0;
    //         }
    //         else
    //             printf("EDDSA Signature/Verification succeeded \n");
    //     }
    // }

    if (ca.type == X509_RSA)
    {
        printf("Checking CA's RSA Signature on Cert\n");
        PK.e = 65537; // assuming this!
        RSA_2048_fromOctet(PK.n, &CAKEY);

        sha = 0;

        if (st.hash == X509_H256) sha = SHA256;
        if (st.hash == X509_H384) sha = SHA384;
        if (st.hash == X509_H512) sha = SHA512;
        if (sha == 0)
        {
            printf("Hash Function not supported\n");
            return 0;
        }
        PKCS15(sha, &H, &HP);

        RSA_2048_ENCRYPT(&PK, &SIG, &HH);

        if (OCT_comp(&HP, &HH))
            printf("RSA Signature/Verification succeeded \n");
        else
            printf("***RSA Verification Failed\n");
    }

    return 0;
}
