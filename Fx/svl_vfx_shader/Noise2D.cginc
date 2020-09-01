#ifndef MY_CG_INCLUDE
#define MY_CG_INCLUDE
		fixed3 mod2D289( fixed3 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
		fixed2 mod2D289( fixed2 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
		fixed3 permute( fixed3 x ) { return mod2D289( ( ( x * 34.0 ) + 1.0 ) * x ); }
		fixed noise2D( fixed2 v )
		{
			const fixed4 C = fixed4( 0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439 );
			fixed2 i = floor( v + dot( v, C.yy ) );
			fixed2 x0 = v - i + dot( i, C.xx );
			fixed2 i1;
			i1 = ( x0.x > x0.y ) ? fixed2( 1.0, 0.0 ) : fixed2( 0.0, 1.0 );
			fixed4 x12 = x0.xyxy + C.xxzz;
			x12.xy -= i1;
			i = mod2D289( i );
			fixed3 p = permute( permute( i.y + fixed3( 0.0, i1.y, 1.0 ) ) + i.x + fixed3( 0.0, i1.x, 1.0 ) );
			fixed3 m = max( 0.5 - fixed3( dot( x0, x0 ), dot( x12.xy, x12.xy ), dot( x12.zw, x12.zw ) ), 0.0 );
			m = m * m;
			m = m * m;
			fixed3 x = 2.0 * frac( p * C.www ) - 1.0;
			fixed3 h = abs( x ) - 0.5;
			fixed3 ox = floor( x + 0.5 );
			fixed3 a0 = x - ox;
			m *= 1.79284291400159 - 0.85373472095314 * ( a0 * a0 + h * h );
			fixed3 g;
			g.x = a0.x * x0.x + h.x * x0.y;
			g.yz = a0.yz * x12.xz + h.yz * x12.yw;
			return 130.0 * dot( m, g );
		}
#endif