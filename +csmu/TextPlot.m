classdef TextPlot < csmu.PlotBuilder
  
   properties
      X
      Y
      Z
      Text
   end
   
   properties (Constant)
     ShadowClass = 'matlab.graphics.primitive.Text'
     ShadowClassTag = ''
     ShadowClassExcludeList = ''
   end
   
   methods
      function plotGraphics(self, axisHandle)               
         disp(self.X(1))
         if isempty(self.Z)
            posFun = @(i) {self.X(i), self.Y(i)};
         else
            posFun = @(i) {self.X(i), self.Y(i), self.Z(i)};
         end
         
         % FIXME - allow setting X and Y with Position Property
         
         function textHelper(iText)
            posArgs = posFun(iText);
            if length(self.X) > 1
               str = csmu.loopIndexCell(self.Text, iText);
            else
               if iscell(self.Text)
                  str = self.Text{1};
               else
                  str = self.Text;
               end
            end         
            textHandle = text(axisHandle, posArgs{:}, str);
            self.applyShadowClassProps(textHandle);
         end         
         
         for iText = 1:length(self.X)
            textHelper(iText);
         end
      end
      
      function set.Text(self, val)
         self.Text = csmu.tocell(val);
      end

   end
   
end