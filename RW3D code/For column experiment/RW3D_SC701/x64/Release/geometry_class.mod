	  7+  m   k820309              15.0        ���W                                                                                                           
       C:\Users\Dong\Documents\Visual Studio 2013\Projects\RW3D_SC701\RW3D_SC701\RW3D_source\geometry_class.f90 GEOMETRY_CLASS              GEOMETRY_CL ASSIGN_GEOMETRY_ DX_ DY_ DZ_ LOCATE_CELL_ DELETE_GEOMETRY_ MESH_COORDINATES_ GET_XMESH_ GET_YMESH_ GET_ZMESH_ INTERPOLATE_ARRAY_ READ_GEOMETRY_ READ_BOUNDARY_ READ_INACTIVE_CELLS_ LENGTH_CELL_ gen@GET_CELL_CENTROID_                      @                              
                                                              u #GET_CELL_CENTROID1_    #GET_CELL_CENTROID2_    (         `    @X                                               
               
    #GET_CELL_CENTROID1_%SUM    #GET_CELL_CENTROID1_%DFLOAT    #NAME    #CELL    p          p            p                                        @                                SUM               @                                DFLOAT           
  @                                    �             #GEOMETRY_CL              
                                                      	   p          p            p                          (         `    @X                                                              
    #GET_CELL_CENTROID2_%SUM 	   #GET_CELL_CENTROID2_%DFLOAT 
   #NAME    #I    #J    #K    p          p            p                                        @                           	     SUM               @                           
     DFLOAT           
  @                                    �             #GEOMETRY_CL              
                                                       
                                                       
                                                               @                              'x                    #VALUES              �$                                                         
            &                   &                   &                                                                                  y
                                                                 @                               '�                   #NX    #NY    #NZ    #DX    #DY    #DZ    #XMESH    #YMESH    #ZMESH    #IB    #INACTCELL                 � $                                                              � $                                                             � $                                                             � $                                   x                     #ARRAY_CL                 � $                                   x       �              #ARRAY_CL                 � $                                   x                     #ARRAY_CL                 � $                                   x       x             #ARRAY_CL                 � $                                   x       �             #ARRAY_CL                 � $                                   x       h      	       #ARRAY_CL               �$                                         �             
              &                   &                                                                                  y                                                          �$                                         @                           &                   &                   &                                                                                  y                                               #         @                                                       #NAME    #N1    #N2    #N3     #D1 !   #D2 "   #D3 #   #I $             
D                                      �              #GEOMETRY_CL              
                                                       
                                                       
                                                        
  @                              !     
                
                                 "     
                
                                 #     
                
                                  $                       p          p          p            p          p                          %         @                                 %                   
       #DX_%SIZE &   #NAME '   #I (   #J )   #K *                 @                           &     SIZE           
                                  '     �             #GEOMETRY_CL              
                                  (                     
                                  )                     
                                  *           %         @                                 +                   
       #DY_%SIZE ,   #NAME -   #I .   #J /   #K 0                 @                           ,     SIZE           
                                  -     �             #GEOMETRY_CL              
                                  .                     
                                  /                     
                                  0           %         @                                 1                   
       #DZ_%SIZE 2   #NAME 3   #I 4   #J 5   #K 6                 @                           2     SIZE           
                                  3     �             #GEOMETRY_CL              
                                  4                     
                                  5                     
                                  6           #         @                                   7                   #LOCATE_CELL_%DINT 8   #THIS 9   #XP :   #CELL ;                 @                           8     DINT           
  @                               9     �             #GEOMETRY_CL              
@ @                              :                   
    p          p            p                                    D @                               ;                        p          p            p                          #         @                                   <                    #NAME =             
D @                               =     �              #GEOMETRY_CL    #         @                                   >                    #NAME ?             
D @                               ?     �              #GEOMETRY_CL    %         @                                 @                   
       #GET_XMESH_%DFLOAT A   #NAME B   #I C                 @                           A     DFLOAT           
  @                               B     �             #GEOMETRY_CL              
                                  C           %         @                                 D                   
       #GET_YMESH_%DFLOAT E   #NAME F   #J G                 @                           E     DFLOAT           
  @                               F     �             #GEOMETRY_CL              
                                  G           %         @                                 H                   
       #GET_ZMESH_%DFLOAT I   #NAME J   #K K                 @                           I     DFLOAT           
  @                               J     �             #GEOMETRY_CL              
                                  K           %         @                                 L                   
       #INTERPOLATE_ARRAY_%ARRAY_CL M   #THIS O   #ARRAY P   #CELL Q   #COORD R                     @                          M     'x                    #VALUES N             �$                            N                             
            &                   &                   &                                                                                  y
                                                         
  @                               O     �             #GEOMETRY_CL              
  @                               P     x              #INTERPOLATE_ARRAY_%ARRAY_CL M             
                                  Q                       p          p            p                                    
                                 R                   
    p          p            p                          #         @                                   S                    #THIS T   #UNIT U             
D                                 T     �              #GEOMETRY_CL              
                                  U           #         @                                   V                   #READ_BOUNDARY_%ASSOCIATED W   #THIS X   #UNIT Y                 @                           W     ASSOCIATED           
D                                 X     �              #GEOMETRY_CL              
                                  Y           #         @                                   Z                   #READ_INACTIVE_CELLS_%ASSOCIATED [   #READ_INACTIVE_CELLS_%TRIM \   #THIS ]   #FNAME ^   #IVAR _   #CONST `   #FLAG a   #NX b   #NY c   #NZ d                 @                           [     ASSOCIATED               @                           \     TRIM           
D                                 ]     �              #GEOMETRY_CL              
  @                              ^                    1           
                                  _                     
                                 `     
                
                                  a                     
                                  b                     
                                  c                     
                                  d           (         `                                 e                                  
    #LENGTH_CELL_%SIZE f   #NAME g   #I h   #J i   #K j   p          p            p                                        @                           f     SIZE           
                                  g     �             #GEOMETRY_CL              
                                  h                     
                                  i                     
                                  j              �   �      fn#fn $      �   b   uapp(GEOMETRY_CLASS      @   J  ARRAY_CLASS '   T  r       gen@GET_CELL_CENTROID_ $   �  �      GET_CELL_CENTROID1_ (   �  <      GET_CELL_CENTROID1_%SUM +   �  ?      GET_CELL_CENTROID1_%DFLOAT )   6  Y   a   GET_CELL_CENTROID1_%NAME )   �  �   a   GET_CELL_CENTROID1_%CELL $   #        GET_CELL_CENTROID2_ (   #  <      GET_CELL_CENTROID2_%SUM +   _  ?      GET_CELL_CENTROID2_%DFLOAT )   �  Y   a   GET_CELL_CENTROID2_%NAME &   �  @   a   GET_CELL_CENTROID2_%I &   7  @   a   GET_CELL_CENTROID2_%J &   w  @   a   GET_CELL_CENTROID2_%K %   �  \       ARRAY_CL+ARRAY_CLASS ,     $  a   ARRAY_CL%VALUES+ARRAY_CLASS    7	  �       GEOMETRY_CL    �	  H   a   GEOMETRY_CL%NX    7
  H   a   GEOMETRY_CL%NY    
  H   a   GEOMETRY_CL%NZ    �
  ^   a   GEOMETRY_CL%DX    %  ^   a   GEOMETRY_CL%DY    �  ^   a   GEOMETRY_CL%DZ "   �  ^   a   GEOMETRY_CL%XMESH "   ?  ^   a   GEOMETRY_CL%YMESH "   �  ^   a   GEOMETRY_CL%ZMESH    �    a   GEOMETRY_CL%IB &     $  a   GEOMETRY_CL%INACTCELL !   +  �       ASSIGN_GEOMETRY_ &   �  Y   a   ASSIGN_GEOMETRY_%NAME $     @   a   ASSIGN_GEOMETRY_%N1 $   M  @   a   ASSIGN_GEOMETRY_%N2 $   �  @   a   ASSIGN_GEOMETRY_%N3 $   �  @   a   ASSIGN_GEOMETRY_%D1 $     @   a   ASSIGN_GEOMETRY_%D2 $   M  @   a   ASSIGN_GEOMETRY_%D3 #   �  �   a   ASSIGN_GEOMETRY_%I    A  }       DX_    �  =      DX_%SIZE    �  Y   a   DX_%NAME    T  @   a   DX_%I    �  @   a   DX_%J    �  @   a   DX_%K      }       DY_    �  =      DY_%SIZE    �  Y   a   DY_%NAME    '  @   a   DY_%I    g  @   a   DY_%J    �  @   a   DY_%K    �  }       DZ_    d  =      DZ_%SIZE    �  Y   a   DZ_%NAME    �  @   a   DZ_%I    :  @   a   DZ_%J    z  @   a   DZ_%K    �  {       LOCATE_CELL_ "   5  =      LOCATE_CELL_%DINT "   r  Y   a   LOCATE_CELL_%THIS     �  �   a   LOCATE_CELL_%XP "   _  �   a   LOCATE_CELL_%CELL !   �  R       DELETE_GEOMETRY_ &   E  Y   a   DELETE_GEOMETRY_%NAME "   �  R       MESH_COORDINATES_ '   �  Y   a   MESH_COORDINATES_%NAME    I  x       GET_XMESH_ "   �  ?      GET_XMESH_%DFLOAT        Y   a   GET_XMESH_%NAME    Y  @   a   GET_XMESH_%I    �  x       GET_YMESH_ "     ?      GET_YMESH_%DFLOAT     P  Y   a   GET_YMESH_%NAME    �  @   a   GET_YMESH_%J    �  x       GET_ZMESH_ "   a  ?      GET_ZMESH_%DFLOAT     �  Y   a   GET_ZMESH_%NAME    �  @   a   GET_ZMESH_%K #   9  �       INTERPOLATE_ARRAY_ 8   �  \      INTERPOLATE_ARRAY_%ARRAY_CL+ARRAY_CLASS ?   0   $  a   INTERPOLATE_ARRAY_%ARRAY_CL%VALUES+ARRAY_CLASS (   T!  Y   a   INTERPOLATE_ARRAY_%THIS )   �!  i   a   INTERPOLATE_ARRAY_%ARRAY (   "  �   a   INTERPOLATE_ARRAY_%CELL )   �"  �   a   INTERPOLATE_ARRAY_%COORD    >#  \       READ_GEOMETRY_ $   �#  Y   a   READ_GEOMETRY_%THIS $   �#  @   a   READ_GEOMETRY_%UNIT    3$  {       READ_BOUNDARY_ *   �$  C      READ_BOUNDARY_%ASSOCIATED $   �$  Y   a   READ_BOUNDARY_%THIS $   J%  @   a   READ_BOUNDARY_%UNIT %   �%  �       READ_INACTIVE_CELLS_ 0   b&  C      READ_INACTIVE_CELLS_%ASSOCIATED *   �&  =      READ_INACTIVE_CELLS_%TRIM *   �&  Y   a   READ_INACTIVE_CELLS_%THIS +   ;'  L   a   READ_INACTIVE_CELLS_%FNAME *   �'  @   a   READ_INACTIVE_CELLS_%IVAR +   �'  @   a   READ_INACTIVE_CELLS_%CONST *   (  @   a   READ_INACTIVE_CELLS_%FLAG (   G(  @   a   READ_INACTIVE_CELLS_%NX (   �(  @   a   READ_INACTIVE_CELLS_%NY (   �(  @   a   READ_INACTIVE_CELLS_%NZ    )  �       LENGTH_CELL_ "   �)  =      LENGTH_CELL_%SIZE "   *  Y   a   LENGTH_CELL_%NAME    w*  @   a   LENGTH_CELL_%I    �*  @   a   LENGTH_CELL_%J    �*  @   a   LENGTH_CELL_%K 