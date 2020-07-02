function tableFind(tab,el)
    for index, value in pairs(tab) do
        if value == el then
            return index
        end
    end
    return -1
end

function rot(x,y,a)
	return math.cos(a)*x-math.sin(a)*y,math.sin(a)*x+math.cos(a)*y
end

function harmonic(t, d, f, p, a)
	return a*math.sin(2*math.pi*f*t/d +2*math.pi*p)
end

function smollest(x)
	smol = x
	for i=1,x/2 do
		if x % i == 0 then
			if math.max(i,x/i) < math.max(smol,x/smol) then
				smol = i
			end
		end
	end
	return smol
end