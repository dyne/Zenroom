<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
   "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
<head>
    <title>Zenroom LUA</title>
    <link rel="stylesheet" href="" type="text/css" />
</head>
<body>

<div id="container">

<div id="product">
	<div id="product_logo"></div>
	<div id="product_name"><big><b></b></big></div>
	<div id="product_description"></div>
</div> <!-- id="product" -->


<div id="main">


<!-- Menu -->

<div id="navigation">
<br/>
<h1>Zenroom</h1>





<h2>Modules</h2>
<ul class="nowrap">
  <li><a href="modules/OCTET.html">OCTET</a></li>
  <li><a href="modules/HASH.html">HASH</a></li>
  <li><a href="modules/ECP.html">ECP</a></li>
  <li><a href="modules/BIG.html">BIG</a></li>
  <li><a href="modules/FLOAT.html">FLOAT</a></li>
  <li><a href="modules/TIME.html">TIME</a></li>
  <li><a href="modules/AES.html">AES</a></li>
  <li><a href="modules/ECDH.html">ECDH</a></li>
  <li><a href="modules/ED.html">ED</a></li>
  <li><a href="modules/P256.html">P256</a></li>
  <li><a href="modules/QP.html">QP</a></li>
  <li><a href="modules/String.html">String</a></li>
  <li><a href="modules/Table.html">Table</a></li>
  <li><a href="modules/INSPECT.html">INSPECT</a></li>
  <li><a href="modules/lua.zencode.html">lua.zencode</a></li>
  <li><a href="modules/BBS.html">BBS</a></li>
</ul>

</div>

<div id="content">


  <h2>Documentation of Lua scripting in Zenroom</h2>
  <p>Zenroom is a portable language interpreter inspired by
language-theoretical security and designed to be small,
attack-resistant and very portable. Its main use case is distributed
computing of untrusted code, for instance it can be used for delicate
cryptographic operations.  Here is the documentation of the
cryptographic primitive functions that are made available by the Lua
direct-syntax parser in Zenroom.</p>

<p>For more information see the homepage of this project: <a
href="https://zenroom.org">Zenroom.org</a>.</p>

<p><img src="https://www.dyne.org/wp-content/uploads/2015/12/software_by_dyne.png" alt="Software by Dyne.org"></p>

<h2>Modules</h2>
<table class="module_list">
	<tr>
		<td class="name"  nowrap><a href="modules/OCTET.html">OCTET</a></td>
		<td class="summary">

<h1>Array of raw bytes: base data type in Zenroom</h1>


<p>  Octets are <a
  href="https://en.wikipedia.org/wiki/First-class_citizen">first-class
  citizens</a> in Zenroom.</p>
</td>
	</tr>
	<tr>
		<td class="name"  nowrap><a href="modules/HASH.html">HASH</a></td>
		<td class="summary">

<h1>Cryptographic hash functions</h1>


<p> An hash is also known as 'message digest', 'digital fingerprint',
 'digest' or 'checksum'.</p>
</td>
	</tr>
	<tr>
		<td class="name"  nowrap><a href="modules/ECP.html">ECP</a></td>
		<td class="summary">

<h1>Elliptic Curve Point Arithmetic (ECP)</h1>


<p>  Base arithmetical operations on elliptic curve point coordinates.</p>
</td>
	</tr>
	<tr>
		<td class="name"  nowrap><a href="modules/BIG.html">BIG</a></td>
		<td class="summary">

<h1>Big Number Arithmetic (BIG)</h1>


<p> Base arithmetical operations on big numbers.</p>
</td>
	</tr>
	<tr>
		<td class="name"  nowrap><a href="modules/FLOAT.html">FLOAT</a></td>
		<td class="summary">

<h1>Float (F)</h1>


<p>Floating-point numbers are a fundamental data type in computing used to represent real numbers (numbers with fractional parts).</p>
</td>
	</tr>
	<tr>
		<td class="name"  nowrap><a href="modules/TIME.html">TIME</a></td>
		<td class="summary">

<h1>TIME</h1>

<p>This class allows to work with TIME objects.</p>
</td>
	</tr>
	<tr>
		<td class="name"  nowrap><a href="modules/AES.html">AES</a></td>
		<td class="summary">

<h1>Advanced Encryption Standard (AES)</h1>


<p>  AES Block cipher in varoius modes.</p>
</td>
	</tr>
	<tr>
		<td class="name"  nowrap><a href="modules/ECDH.html">ECDH</a></td>
		<td class="summary">

<h1>Elliptic Curve Diffie-Hellman encryption (ECDH)</h1>


<p>  Asymmetric public/private key encryption technologies.</p>
</td>
	</tr>
	<tr>
		<td class="name"  nowrap><a href="modules/ED.html">ED</a></td>
		<td class="summary">

<h1>Ed25519 signature scheme (ED)</h1>

<p> This module provides algorithms and functions for an elliptic curve signature scheme.</p>
</td>
	</tr>
	<tr>
		<td class="name"  nowrap><a href="modules/P256.html">P256</a></td>
		<td class="summary">

<h1>P256 </h1>

<p>P-256 (also known as secp256r1 or prime256v1) is one of the most widely used elliptic curves in modern cryptography.</p>
</td>
	</tr>
	<tr>
		<td class="name"  nowrap><a href="modules/QP.html">QP</a></td>
		<td class="summary">

<h1> POST QUANTUM (QP) </h1>


<p> Post-quantum cryptography (PQC) refers to cryptographic algorithms that are designed to be secure against attacks by quantum computers.</p>
</td>
	</tr>
	<tr>
		<td class="name"  nowrap><a href="modules/String.html">String</a></td>
		<td class="summary">

<h1>String operations</h1>

<p> Standard Lua string manipulation like searching and matching.</p>
</td>
	</tr>
	<tr>
		<td class="name"  nowrap><a href="modules/Table.html">Table</a></td>
		<td class="summary">

<h1>Table operations</h1>

<p> Standard Lua data structure manipulation on maps (key/value) and arrays.</p>
</td>
	</tr>
	<tr>
		<td class="name"  nowrap><a href="modules/INSPECT.html">INSPECT</a></td>
		<td class="summary">

<h1>Debug inspection facility</h1>


<p> The INSPECT class provides a number of functions to ease
 development and debugging.</p>
</td>
	</tr>
	<tr>
		<td class="name"  nowrap><a href="modules/lua.zencode.html">lua.zencode</a></td>
		<td class="summary">ZENCODE WATCHDOG
 assert all values in table are converted to zenroom types
 used in zencode when transitioning out of given memory</td>
	</tr>
	<tr>
		<td class="name"  nowrap><a href="modules/BBS.html">BBS</a></td>
		<td class="summary">

<h1>BBS signature scheme</h1>


<p> The BBS signature scheme (also known as the Boneh-Boyen-Shacham signature scheme)
 is a cryptographic signature scheme based on pairing-based cryptography: the BBS scheme is particularly
 notable for its use of bilinear pairings on elliptic curves,
 which enable efficient verification and compact signatures.</p>
</td>
	</tr>
</table>

</div> <!-- id="content" -->
</div> <!-- id="main" -->
<div id="about">
<i>generated by <a href="http://github.com/lunarmodules/LDoc">LDoc 1.5.0</a></i>
<i style="float:right;">Last updated 2025-03-25 10:33:58 </i>
</div> <!-- id="about" -->
</div> <!-- id="container" -->
</body>
</html>
