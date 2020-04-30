declare module 'zenroom' {
	export function script(script: string):any;
	export function success():any;
	export function error():any;
	export function print(text: string): any;
	export function print_err(text:string): any;
	export function keys(keys: any): any
	export function data(data: any): any
	export function conf(conf: string): any;
	export function zenroom_exec(): any;
	export function zencode_exec(): any;
	export function init(options: any): any;
	export function reset(): any;
}
