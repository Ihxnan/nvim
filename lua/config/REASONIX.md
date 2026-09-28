# Reasonix project memory

Notes the user pinned via the `#` prompt prefix. The whole file is
loaded into the immutable system prefix every session — keep it terse.

- include <bits/stdc++.h>
#define ls(x) ((x) << 1)
#define rs(x) ((x) << 1 | 1)
#define bi(x) (((x) - 1) / blen)
#define bl(x) ((x) * blen + 1)
#define br(x) (min(((x) + 1) * blen, n))
#define lowbit(x) ((x) & -(x))
#define fid(x,y) ((m)*(x-1)+(y))
#define endl '\n'
#ifdef IHXNAN
    #include <dbg>
#else
    #define gdb(...)              ((void)0)
    #define gdbif(c, ...)         ((void)0)
    #define gdb_assert(cond, msg) ((void)0)
    #define TIME(name)            ((void)0)
    #define gc() (p1==p2&&(p2=(p1=buf)+fread(buf,1,S,stdin),p1==p2)?EOF:*p1++)
    #define pc(c) (Top==S&&(clear(),0), buf[Top++]=c)
#endif
using namespace std;using ll = long long;using ul = unsigned long long;using lll = __int128;using vb = vector<bool>;using vi = vector<int>;using vvi = vector<vi>;using vl = vector<ll>;using vvl = vector<vl>;using pii = pair<int, int>;using pll = pair<ll, ll>;using ti = tuple<int, int, int>;
struct IO{
#define cin fin
#define cout fout
    static const int S=1<<21;
    uint8_t buf[S],*p1,*p2;int st[105],Top;
    ~IO(){clear();}
    inline void clear(){fwrite(buf,1,Top,stdout);Top=0;}
    inline IO&operator>>(char&x){while(isspace(x=gc()));return *this;}
    inline IO&operator>>(string&x){x.clear();int c;while(isspace(c=gc()));while(!isspace(c))x+=char(c),c=gc();return*this;}
    template<typename T>inline IO&operator>>(T&x){x=0;int f=0,ch=gc();while(!isdigit(ch)){if(ch=='-')f^=1;ch=gc();}while(isdigit(ch))x=(x<<3)+(x<<1)+(ch^48),ch=gc();f?x=-x:0;return*this;}
    inline IO&operator<<(char c){pc(c);return*this;}
    inline IO&operator<<(const char*x){while(*x)pc(*x++);return*this;}
    inline IO&operator<<(const string&x){for(auto c:x)pc(c);return*this;}
    template<typename T>inline IO&operator<<(T x){int f=0;if(x<0)pc('-'),f^=1;do{st[++st[0]]=f?-(x%10):x%10,x/=10;}while(x);while(st[0])pc(48^st[st[0]--]);return*this;}
}fin,fout;
int iINF = 0x3f3f3f3f, mod = 998244353;ll lINF = 0x3f3f3f3f3f3f3f3f, MOD = 1000000007;

void solve();

int main()
{
    int t = 1;
#ifdef MULTIT
        scanf("%d", &t);
#endif
    while (t--)
        solve();
    return 0;
}
本地运行定义gc为getchar, 重定向会卡住
