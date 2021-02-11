// https://d3js.org/d3-array/ v2.11.0 Copyright 2021 Mike Bostock
!function(t,n){"object"==typeof exports&&"undefined"!=typeof module?n(exports):"function"==typeof define&&define.amd?define(["exports"],n):n((t="undefined"!=typeof globalThis?globalThis:t||self).d3=t.d3||{})}(this,(function(t){"use strict";function n(t,n){return t<n?-1:t>n?1:t>=n?0:NaN}function r(t){let r=t,e=t;function o(t,n,r,o){for(null==r&&(r=0),null==o&&(o=t.length);r<o;){const f=r+o>>>1;e(t[f],n)<0?r=f+1:o=f}return r}return 1===t.length&&(r=(n,r)=>t(n)-r,e=function(t){return(r,e)=>n(t(r),e)}(t)),{left:o,center:function(t,n,e,f){null==e&&(e=0),null==f&&(f=t.length);const i=o(t,n,e,f-1);return i>e&&r(t[i-1],n)>-r(t[i],n)?i-1:i},right:function(t,n,r,o){for(null==r&&(r=0),null==o&&(o=t.length);r<o;){const f=r+o>>>1;e(t[f],n)>0?o=f:r=f+1}return r}}}function e(t){return null===t?NaN:+t}const o=r(n),f=o.right,i=o.left,u=r(e).center;function l(t,n){let r=0;if(void 0===n)for(let n of t)null!=n&&(n=+n)>=n&&++r;else{let e=-1;for(let o of t)null!=(o=n(o,++e,t))&&(o=+o)>=o&&++r}return r}function s(t){return 0|t.length}function c(t){return!(t>0)}function a(t){return"object"!=typeof t||"length"in t?t:Array.from(t)}function h(t,n){let r,e=0,o=0,f=0;if(void 0===n)for(let n of t)null!=n&&(n=+n)>=n&&(r=n-o,o+=r/++e,f+=r*(n-o));else{let i=-1;for(let u of t)null!=(u=n(u,++i,t))&&(u=+u)>=u&&(r=u-o,o+=r/++e,f+=r*(u-o))}if(e>1)return f/(e-1)}function d(t,n){const r=h(t,n);return r?Math.sqrt(r):r}function p(t,n){let r,e;if(void 0===n)for(const n of t)null!=n&&(void 0===r?n>=n&&(r=e=n):(r>n&&(r=n),e<n&&(e=n)));else{let o=-1;for(let f of t)null!=(f=n(f,++o,t))&&(void 0===r?f>=f&&(r=e=f):(r>f&&(r=f),e<f&&(e=f)))}return[r,e]}class y{constructor(){this._partials=new Float64Array(32),this._n=0}add(t){const n=this._partials;let r=0;for(let e=0;e<this._n&&e<32;e++){const o=n[e],f=t+o,i=Math.abs(t)<Math.abs(o)?t-(f-o):o-(f-t);i&&(n[r++]=i),t=f}return n[r]=t,this._n=r+1,this}valueOf(){const t=this._partials;let n,r,e,o=this._n,f=0;if(o>0){for(f=t[--o];o>0&&(n=f,r=t[--o],f=n+r,e=r-(f-n),!e););o>0&&(e<0&&t[o-1]<0||e>0&&t[o-1]>0)&&(r=2*e,n=f+r,r==n-f&&(f=n))}return f}}class v extends Map{constructor(t=[],n=b){super(),Object.defineProperties(this,{_intern:{value:new Map},_key:{value:n}});for(const[n,r]of t)this.set(n,r)}get(t){return super.get(m(this,t))}has(t){return super.has(m(this,t))}set(t,n){return super.set(M(this,t),n)}delete(t){return super.delete(w(this,t))}}class g extends Set{constructor(t=[],n=b){super(),Object.defineProperties(this,{_intern:{value:new Map},_key:{value:n}});for(const n of t)this.add(n)}has(t){return super.has(m(this,t))}add(t){return super.add(M(this,t))}delete(t){return super.delete(w(this,t))}}function m({_intern:t,_key:n},r){const e=n(r);return t.has(e)?t.get(e):r}function M({_intern:t,_key:n},r){const e=n(r);return t.has(e)?t.get(e):(t.set(e,r),r)}function w({_intern:t,_key:n},r){const e=n(r);return t.has(e)&&(r=t.get(r),t.delete(e)),r}function b(t){return null!==t&&"object"==typeof t?t.valueOf():t}function A(t){return t}function x(t,...n){return k(t,A,A,n)}function S(t,n,...r){return k(t,A,n,r)}function _(t){if(1!==t.length)throw new Error("duplicate key");return t[0]}function k(t,n,r,e){return function t(o,f){if(f>=e.length)return r(o);const i=new v,u=e[f++];let l=-1;for(const t of o){const n=u(t,++l,o),r=i.get(n);r?r.push(t):i.set(n,[t])}for(const[n,r]of i)i.set(n,t(r,f));return n(i)}(t,0)}function T(t,n){return Array.from(n,n=>t[n])}function j(t,...r){if("function"!=typeof t[Symbol.iterator])throw new TypeError("values is not iterable");t=Array.from(t);let[e=n]=r;if(1===e.length||r.length>1){const o=Uint32Array.from(t,(t,n)=>n);return r.length>1?(r=r.map(n=>t.map(n)),o.sort((t,e)=>{for(const o of r){const r=n(o[t],o[e]);if(r)return r}})):(e=t.map(e),o.sort((t,r)=>n(e[t],e[r]))),T(t,o)}return t.sort(e)}var E=Array.prototype.slice;function N(t){return function(){return t}}var q=Math.sqrt(50),F=Math.sqrt(10),I=Math.sqrt(2);function O(t,n,r){var e,o,f,i,u=-1;if(r=+r,(t=+t)===(n=+n)&&r>0)return[t];if((e=n<t)&&(o=t,t=n,n=o),0===(i=L(t,n,r))||!isFinite(i))return[];if(i>0)for(t=Math.ceil(t/i),n=Math.floor(n/i),f=new Array(o=Math.ceil(n-t+1));++u<o;)f[u]=(t+u)*i;else for(i=-i,t=Math.ceil(t*i),n=Math.floor(n*i),f=new Array(o=Math.ceil(n-t+1));++u<o;)f[u]=(t+u)/i;return e&&f.reverse(),f}function L(t,n,r){var e=(n-t)/Math.max(0,r),o=Math.floor(Math.log(e)/Math.LN10),f=e/Math.pow(10,o);return o>=0?(f>=q?10:f>=F?5:f>=I?2:1)*Math.pow(10,o):-Math.pow(10,-o)/(f>=q?10:f>=F?5:f>=I?2:1)}function P(t,n,r){let e;for(;;){const o=L(t,n,r);if(o===e||0===o||!isFinite(o))return[t,n];o>0?(t=Math.floor(t/o)*o,n=Math.ceil(n/o)*o):o<0&&(t=Math.ceil(t*o)/o,n=Math.floor(n*o)/o),e=o}}function z(t){return Math.ceil(Math.log(l(t))/Math.LN2)+1}function C(){var t=A,n=p,r=z;function e(e){Array.isArray(e)||(e=Array.from(e));var o,i,u=e.length,l=new Array(u);for(o=0;o<u;++o)l[o]=t(e[o],o,e);var s=n(l),c=s[0],a=s[1],h=r(l,c,a);if(!Array.isArray(h)){const t=a,r=+h;if(n===p&&([c,a]=P(c,a,r)),(h=O(c,a,r))[h.length-1]>=a)if(t>=a&&n===p){const t=L(c,a,r);isFinite(t)&&(t>0?a=(Math.floor(a/t)+1)*t:t<0&&(a=(Math.ceil(a*-t)+1)/-t))}else h.pop()}for(var d=h.length;h[0]<=c;)h.shift(),--d;for(;h[d-1]>a;)h.pop(),--d;var y,v=new Array(d+1);for(o=0;o<=d;++o)(y=v[o]=[]).x0=o>0?h[o-1]:c,y.x1=o<d?h[o]:a;for(o=0;o<u;++o)c<=(i=l[o])&&i<=a&&v[f(h,i,0,d)].push(e[o]);return v}return e.value=function(n){return arguments.length?(t="function"==typeof n?n:N(n),e):t},e.domain=function(t){return arguments.length?(n="function"==typeof t?t:N([t[0],t[1]]),e):n},e.thresholds=function(t){return arguments.length?(r="function"==typeof t?t:Array.isArray(t)?N(E.call(t)):N(t),e):r},e}function D(t,n){let r;if(void 0===n)for(const n of t)null!=n&&(r<n||void 0===r&&n>=n)&&(r=n);else{let e=-1;for(let o of t)null!=(o=n(o,++e,t))&&(r<o||void 0===r&&o>=o)&&(r=o)}return r}function R(t,n){let r;if(void 0===n)for(const n of t)null!=n&&(r>n||void 0===r&&n>=n)&&(r=n);else{let e=-1;for(let o of t)null!=(o=n(o,++e,t))&&(r>o||void 0===r&&o>=o)&&(r=o)}return r}function U(t,r,e=0,o=t.length-1,f=n){for(;o>e;){if(o-e>600){const n=o-e+1,i=r-e+1,u=Math.log(n),l=.5*Math.exp(2*u/3),s=.5*Math.sqrt(u*l*(n-l)/n)*(i-n/2<0?-1:1);U(t,r,Math.max(e,Math.floor(r-i*l/n+s)),Math.min(o,Math.floor(r+(n-i)*l/n+s)),f)}const n=t[r];let i=e,u=o;for(B(t,e,r),f(t[o],n)>0&&B(t,e,o);i<u;){for(B(t,i,u),++i,--u;f(t[i],n)<0;)++i;for(;f(t[u],n)>0;)--u}0===f(t[e],n)?B(t,e,u):(++u,B(t,u,o)),u<=r&&(e=u+1),r<=u&&(o=u-1)}return t}function B(t,n,r){const e=t[n];t[n]=t[r],t[r]=e}function G(t,n,r){if(e=(t=Float64Array.from(function*(t,n){if(void 0===n)for(let n of t)null!=n&&(n=+n)>=n&&(yield n);else{let r=-1;for(let e of t)null!=(e=n(e,++r,t))&&(e=+e)>=e&&(yield e)}}(t,r))).length){if((n=+n)<=0||e<2)return R(t);if(n>=1)return D(t);var e,o=(e-1)*n,f=Math.floor(o),i=D(U(t,f).subarray(0,f+1));return i+(R(t.subarray(f+1))-i)*(o-f)}}function H(t,n){let r,e=-1,o=-1;if(void 0===n)for(const n of t)++o,null!=n&&(r<n||void 0===r&&n>=n)&&(r=n,e=o);else for(let f of t)null!=(f=n(f,++o,t))&&(r<f||void 0===r&&f>=f)&&(r=f,e=o);return e}function J(t,n){let r,e=-1,o=-1;if(void 0===n)for(const n of t)++o,null!=n&&(r>n||void 0===r&&n>=n)&&(r=n,e=o);else for(let f of t)null!=(f=n(f,++o,t))&&(r>f||void 0===r&&f>=f)&&(r=f,e=o);return e}function K(t,n){return[t,n]}function Q(t,r=n){if(1===r.length)return J(t,r);let e,o=-1,f=-1;for(const n of t)++f,(o<0?0===r(n,n):r(n,e)<0)&&(e=n,o=f);return o}var V=W(Math.random);function W(t){return function(n,r=0,e=n.length){let o=e-(r=+r);for(;o;){const e=t()*o--|0,f=n[o+r];n[o+r]=n[e+r],n[e+r]=f}return n}}function X(t){if(!(o=t.length))return[];for(var n=-1,r=R(t,Y),e=new Array(r);++n<r;)for(var o,f=-1,i=e[n]=new Array(o);++f<o;)i[f]=t[f][n];return e}function Y(t){return t.length}function Z(t){return t instanceof Set?t:new Set(t)}function $(t,n){const r=t[Symbol.iterator](),e=new Set;for(const t of n){if(e.has(t))continue;let n,o;for(;({value:n,done:o}=r.next());){if(o)return!1;if(e.add(n),Object.is(t,n))break}}return!0}t.Adder=y,t.InternMap=v,t.InternSet=g,t.ascending=n,t.bin=C,t.bisect=f,t.bisectCenter=u,t.bisectLeft=i,t.bisectRight=f,t.bisector=r,t.count=l,t.cross=function(...t){const n="function"==typeof t[t.length-1]&&function(t){return n=>t(...n)}(t.pop()),r=(t=t.map(a)).map(s),e=t.length-1,o=new Array(e+1).fill(0),f=[];if(e<0||r.some(c))return f;for(;;){f.push(o.map((n,r)=>t[r][n]));let i=e;for(;++o[i]===r[i];){if(0===i)return n?f.map(n):f;o[i--]=0}}},t.cumsum=function(t,n){var r=0,e=0;return Float64Array.from(t,void 0===n?t=>r+=+t||0:o=>r+=+n(o,e++,t)||0)},t.descending=function(t,n){return n<t?-1:n>t?1:n>=t?0:NaN},t.deviation=d,t.difference=function(t,...n){t=new Set(t);for(const r of n)for(const n of r)t.delete(n);return t},t.disjoint=function(t,n){const r=n[Symbol.iterator](),e=new Set;for(const n of t){if(e.has(n))return!1;let t,o;for(;({value:t,done:o}=r.next())&&!o;){if(Object.is(n,t))return!1;e.add(t)}}return!0},t.every=function(t,n){if("function"!=typeof n)throw new TypeError("test is not a function");let r=-1;for(const e of t)if(!n(e,++r,t))return!1;return!0},t.extent=p,t.filter=function(t,n){if("function"!=typeof n)throw new TypeError("test is not a function");const r=[];let e=-1;for(const o of t)n(o,++e,t)&&r.push(o);return r},t.fsum=function(t,n){const r=new y;if(void 0===n)for(let n of t)(n=+n)&&r.add(n);else{let e=-1;for(let o of t)(o=+n(o,++e,t))&&r.add(o)}return+r},t.greatest=function(t,r=n){let e,o=!1;if(1===r.length){let f;for(const i of t){const t=r(i);(o?n(t,f)>0:0===n(t,t))&&(e=i,f=t,o=!0)}}else for(const n of t)(o?r(n,e)>0:0===r(n,n))&&(e=n,o=!0);return e},t.greatestIndex=function(t,r=n){if(1===r.length)return H(t,r);let e,o=-1,f=-1;for(const n of t)++f,(o<0?0===r(n,n):r(n,e)>0)&&(e=n,o=f);return o},t.group=x,t.groupSort=function(t,r,e){return(1===r.length?j(S(t,r,e),([t,r],[e,o])=>n(r,o)||n(t,e)):j(x(t,e),([t,e],[o,f])=>r(e,f)||n(t,o))).map(([t])=>t)},t.groups=function(t,...n){return k(t,Array.from,A,n)},t.histogram=C,t.index=function(t,...n){return k(t,A,_,n)},t.indexes=function(t,...n){return k(t,Array.from,_,n)},t.intersection=function(t,...n){t=new Set(t),n=n.map(Z);t:for(const r of t)for(const e of n)if(!e.has(r)){t.delete(r);continue t}return t},t.least=function(t,r=n){let e,o=!1;if(1===r.length){let f;for(const i of t){const t=r(i);(o?n(t,f)<0:0===n(t,t))&&(e=i,f=t,o=!0)}}else for(const n of t)(o?r(n,e)<0:0===r(n,n))&&(e=n,o=!0);return e},t.leastIndex=Q,t.map=function(t,n){if("function"!=typeof t[Symbol.iterator])throw new TypeError("values is not iterable");if("function"!=typeof n)throw new TypeError("mapper is not a function");return Array.from(t,(r,e)=>n(r,e,t))},t.max=D,t.maxIndex=H,t.mean=function(t,n){let r=0,e=0;if(void 0===n)for(let n of t)null!=n&&(n=+n)>=n&&(++r,e+=n);else{let o=-1;for(let f of t)null!=(f=n(f,++o,t))&&(f=+f)>=f&&(++r,e+=f)}if(r)return e/r},t.median=function(t,n){return G(t,.5,n)},t.merge=function(t){return Array.from(function*(t){for(const n of t)yield*n}(t))},t.min=R,t.minIndex=J,t.nice=P,t.pairs=function(t,n=K){const r=[];let e,o=!1;for(const f of t)o&&r.push(n(e,f)),e=f,o=!0;return r},t.permute=T,t.quantile=G,t.quantileSorted=function(t,n,r=e){if(o=t.length){if((n=+n)<=0||o<2)return+r(t[0],0,t);if(n>=1)return+r(t[o-1],o-1,t);var o,f=(o-1)*n,i=Math.floor(f),u=+r(t[i],i,t);return u+(+r(t[i+1],i+1,t)-u)*(f-i)}},t.quickselect=U,t.range=function(t,n,r){t=+t,n=+n,r=(o=arguments.length)<2?(n=t,t=0,1):o<3?1:+r;for(var e=-1,o=0|Math.max(0,Math.ceil((n-t)/r)),f=new Array(o);++e<o;)f[e]=t+e*r;return f},t.reduce=function(t,n,r){if("function"!=typeof n)throw new TypeError("reducer is not a function");const e=t[Symbol.iterator]();let o,f,i=-1;if(arguments.length<3){if(({done:o,value:r}=e.next()),o)return;++i}for(;({done:o,value:f}=e.next()),!o;)r=n(r,f,++i,t);return r},t.reverse=function(t){if("function"!=typeof t[Symbol.iterator])throw new TypeError("values is not iterable");return Array.from(t).reverse()},t.rollup=S,t.rollups=function(t,n,...r){return k(t,Array.from,n,r)},t.scan=function(t,n){const r=Q(t,n);return r<0?void 0:r},t.shuffle=V,t.shuffler=W,t.some=function(t,n){if("function"!=typeof n)throw new TypeError("test is not a function");let r=-1;for(const e of t)if(n(e,++r,t))return!0;return!1},t.sort=j,t.subset=function(t,n){return $(n,t)},t.sum=function(t,n){let r=0;if(void 0===n)for(let n of t)(n=+n)&&(r+=n);else{let e=-1;for(let o of t)(o=+n(o,++e,t))&&(r+=o)}return r},t.superset=$,t.thresholdFreedmanDiaconis=function(t,n,r){return Math.ceil((r-n)/(2*(G(t,.75)-G(t,.25))*Math.pow(l(t),-1/3)))},t.thresholdScott=function(t,n,r){return Math.ceil((r-n)/(3.5*d(t)*Math.pow(l(t),-1/3)))},t.thresholdSturges=z,t.tickIncrement=L,t.tickStep=function(t,n,r){var e=Math.abs(n-t)/Math.max(0,r),o=Math.pow(10,Math.floor(Math.log(e)/Math.LN10)),f=e/o;return f>=q?o*=10:f>=F?o*=5:f>=I&&(o*=2),n<t?-o:o},t.ticks=O,t.transpose=X,t.union=function(...t){const n=new Set;for(const r of t)for(const t of r)n.add(t);return n},t.variance=h,t.zip=function(){return X(arguments)},Object.defineProperty(t,"__esModule",{value:!0})}));
