function Fullspctrm = ConvSmoothing(Fullspctrm,K)

h =[];
for x               = 1:size(Fullspctrm,2)
    g = [];
    for y           = 1:size(Fullspctrm,3)
        v           = squeeze(Fullspctrm(:,x,y))';
        f           = conv(v,K,'same');
        g(:,y) = f;
        clear f
    end
    h = cat(3,h,g);
end
h = permute(h,[1 3 2]);
Fullspctrm = h;