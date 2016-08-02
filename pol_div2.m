function r=pol_div2(b,a)

r=logical([]);
N=length(b);p=length(a);

x=b(1:p);
for k=p:N
    if x(1)==0
        y = false(1,p);
    else
        y = a;
    end
    r = logical(xor(x,y));
    if k==N, break; end
    x = [r(2:33) b(k+1)];
end
r=r(2:end);